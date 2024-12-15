########################
# VPC
########################

# Define VPC
resource "aws_vpc" "main" {
  cidr_block           = var.network.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.common.env}-vpc"
  }
}

########################
# Subnet
########################

# Define private subnets
resource "aws_subnet" "private" {
  for_each          = { for i, s in var.network.private_subnets : i => s }
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.common.region}${each.value.az}"
  cidr_block        = each.value.cidr
  tags = {
    Name = "${var.common.env}-subnet-private-1${each.value.az}"
  }
}

# Define private subnets for VPN
resource "aws_subnet" "private_vpn" {
  for_each          = { for i, s in var.network.private_subnets_for_vpn : i => s }
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.common.region}${each.value.az}"
  cidr_block        = each.value.cidr
  tags = {
    Name = "${var.common.env}-subnet-private-vpn-1${each.value.az}"
  }
}

########################
# Route Table
########################

# Define route table for private subnet
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-rtb-private-${each.key}"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

########################
# Security Group
########################

# Define security group for instances
resource "aws_security_group" "instance" {
  name   = "${var.common.env}-sg-instance"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-sg-instance"
  }
}

resource "aws_vpc_security_group_ingress_rule" "instance" {
  security_group_id = aws_security_group.instance.id
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  referenced_security_group_id = aws_security_group.client_vpn.id
} 

resource "aws_vpc_security_group_egress_rule" "instance" {
  security_group_id = aws_security_group.instance.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Define security group for VPC endpoints
resource "aws_security_group" "vpce" {
  name = "${var.common.env}-sg-vpce"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-sg-vpce"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpce" {
  security_group_id = aws_security_group.vpce.id
  ip_protocol = "tcp"
  from_port = 443
  to_port = 443
  referenced_security_group_id = aws_security_group.instance.id
} 

resource "aws_vpc_security_group_egress_rule" "vpce" {
  security_group_id = aws_security_group.vpce.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

# Define security group for client VPN
resource "aws_security_group" "client_vpn" {
  name   = "${var.common.env}-sg-client-vpn"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.common.env}-sg-client-vpn"
  }
}

resource "aws_vpc_security_group_egress_rule" "client_vpn" {
  security_group_id = aws_security_group.client_vpn.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

########################
# VPC Endpoint
########################

# Define VPC endpoint for SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [for s in aws_subnet.private : s.id]
  security_group_ids = [aws_security_group.vpce.id]
  tags = {
    Name = "${var.common.env}-vpce-ssm"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [for s in aws_subnet.private : s.id]
  security_group_ids = [aws_security_group.vpce.id]
  tags = {
    Name = "${var.common.env}-vpce-ssm-messages"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [for s in aws_subnet.private : s.id]
  security_group_ids = [aws_security_group.vpce.id]
  tags = {
    Name = "${var.common.env}-vpce-ec2-messages"
  }
}

# Define VPC endpoint for CloudWatch
resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.monitoring"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [for s in aws_subnet.private : s.id]
  security_group_ids = [aws_security_group.vpce.id]
  tags = {
    Name = "${var.common.env}-vpce-monitoring"
  }
}

# Define VPC endpoint for CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [for s in aws_subnet.private : s.id]
  security_group_ids = [aws_security_group.vpce.id]
  tags = {
    Name = "${var.common.env}-vpce-logs"
  }
}

# Define VPC endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type   = "Gateway"
  route_table_ids = [aws_route_table.private["0"].id]
  tags = {
    Name = "${var.common.env}-vpce-s3"
  }
}

########################
# Client VPN
########################

# Define Client VPN endpoint
resource "aws_ec2_client_vpn_endpoint" "main" {
  description = "Client VPN endpoint"
  client_cidr_block = var.network.client_vpn_cidr
  server_certificate_arn = data.aws_acm_certificate.vpn_server.arn
  authentication_options {
    type = "certificate-authentication"
    root_certificate_chain_arn = data.aws_acm_certificate.vpn_client.arn
  }
  connection_log_options {
    enabled = false
  }
  vpc_id = aws_vpc.main.id
  dns_servers = [cidrhost(aws_vpc.main.cidr_block, 2)]
  split_tunnel = true
  security_group_ids = [aws_security_group.client_vpn.id]
  tags = {
    Name = "${var.common.env}-client-vpn-endpoint"
  }
}

# Refer to certificates pre-issued on ACM
data "aws_acm_certificate" "vpn_server" {
  domain = "server"
}

data "aws_acm_certificate" "vpn_client" {
  domain = "client1.domain.tld"
}

# Associate Client VPN endpoint with target network
resource "aws_ec2_client_vpn_network_association" "main" {
  for_each = aws_subnet.private_vpn
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id = each.value.id
}

# Define authorization rule for Client VPN
resource "aws_ec2_client_vpn_authorization_rule" "main" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  target_network_cidr = aws_vpc.main.cidr_block
  authorize_all_groups = true
}