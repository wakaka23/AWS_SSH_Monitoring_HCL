data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  common = {
    env = "ssh-monitoring"
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
    }
  
  network = {
    cidr = "172.16.0.0/16"
    private_subnets = [
      {
        az   = "a"
        cidr = "172.16.1.0/24"
      }
    ]
    private_subnets_for_vpn = [
      {
        az   = "a"
        cidr = "172.16.2.0/24"
      }
    ]
    client_vpn_cidr = "172.17.0.0/22"
  }  
}
