########################
# VPC
########################

output "vpc_id" {
  value = aws_vpc.main.id
}

########################
# Subnet
########################

output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}

########################
# Security Group
########################

output "security_group_for_instance_id" {
  value = aws_security_group.instance.id
}