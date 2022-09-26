variable "name_prefix" {
  default = ""
  type    = string
}

variable "password" {
  default   = ""
  type      = string
  sensitive = true
}

variable "number_of_servers" {
  default = 1
}

variable "location" {
  default = "WestEurope"
  type    = string
}
