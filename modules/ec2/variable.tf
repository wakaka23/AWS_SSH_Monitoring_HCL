variable "common" {
  type = object({
    env = string
    region = string
  })
}

variable "network" {
  type = object({
    vpc_id = string
    private_subnet_ids = list(string)
    security_group_for_instance_id = string
  })
}
