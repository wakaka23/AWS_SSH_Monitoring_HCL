variable "target" {
  type = object({
    email_addresses = list(string)
  })
}