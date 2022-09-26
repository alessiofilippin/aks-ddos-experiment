variable "location_list" {
  default = ["WestEurope","UkSouth", "EastUS"]
  type    = list(string)
}

variable "name_prefix" {
  default = "ddos-exp"
  type    = string
}

variable "number_of_servers" {
  default = 1 
}

