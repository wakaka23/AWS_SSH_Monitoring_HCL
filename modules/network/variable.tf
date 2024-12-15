variable "common" {
  type = object({
    env = string
    region = string
  })
}

variable "network" {
	type = object({
		cidr = string
		private_subnets = list(object({
			az = string
			cidr = string
		}))
		private_subnets_for_vpn = list(object({
			az = string
			cidr = string
		}))
		client_vpn_cidr = string
	})
}
