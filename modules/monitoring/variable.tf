variable "common" {
  type = object({
    env = string
    region = string
  })
}

variable "ec2" {
  type = object({
    instance_ids = list(string)
  })
}

variable target {
  type = object({
    email_addresses = list(string)
  })
}
