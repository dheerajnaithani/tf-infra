variable "env_name" {
  type = string
}

variable "top_level_domain_name" {
  type = string
}

variable "customer_domain_prefix" {
  type = set(string)
}
