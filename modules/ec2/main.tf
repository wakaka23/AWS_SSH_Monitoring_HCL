########################
# EC2 Instance
########################

# Get AMI for RHEL 9.4
data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["RHEL-9.4.*"]
  }
}

# Define EC2 instance
resource "aws_instance" "main" {
  for_each               = { for i, s in var.network.private_subnet_ids : i => s }
  ami                    = data.aws_ami.rhel.id
  instance_type          = "t3.large"
  vpc_security_group_ids = [var.network.security_group_for_instance_id]
  subnet_id              = each.value
  key_name               = aws_key_pair.main.key_name
  root_block_device {
    volume_type = "gp3"
    volume_size = "20"
    encrypted   = true
    tags = {
      Name = "${var.common.env}-ebs"
    }
  }
  user_data = templatefile("../../files/script.sh", {
    env_name       = var.common.env,
    instance_index = each.key
  })
  iam_instance_profile = aws_iam_instance_profile.main.name
  depends_on           = [aws_ssm_parameter.cloudwatch_agent]
  tags = {
    Name = "${var.common.env}-ec2-${each.key}"
  }
}

########################
# IAM Role
########################

# Define IAM instance profile for EC2
resource "aws_iam_instance_profile" "main" {
  name = "${var.common.env}-instance-profile"
  role = aws_iam_role.main.name
}

# Define IAM role for EC2
resource "aws_iam_role" "main" {
  name               = "${var.common.env}-role-for-ec2"
  assume_role_policy = data.aws_iam_policy_document.main.json
}

# Define trust policy for EC2 role
data "aws_iam_policy_document" "main" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Define IAM policy for EC2 role
resource "aws_iam_role_policy_attachments_exclusive" "main" {
  role_name = aws_iam_role.main.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
  ]
}

########################
# Key Pair
########################

# Define Secret Key and Public Key
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Define Key Pair on AWS
resource "aws_key_pair" "main" {
  key_name   = "${var.common.env}-key-pair"
  public_key = tls_private_key.main.public_key_openssh
}

# Save Secret Key to local file
resource "local_file" "main" {
  filename        = "../../${var.common.env}-private-key.pem"
  content         = tls_private_key.main.private_key_pem
  file_permission = "0600"
}

########################
# SSM Parameter Store
########################

# Define SSM parameter for CloudWatch Agent
resource "aws_ssm_parameter" "cloudwatch_agent" {
  for_each = { for i, s in var.network.private_subnet_ids : i => s }
  name     = "${var.common.env}-cloudwatch-agent-${each.key}"
  type     = "String"
  value = templatefile("../../files/cloudwatch_agent.json", {
    instance_index = each.key
  })
}
