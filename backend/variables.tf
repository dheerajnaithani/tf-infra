variable "env_name" {
  type = string
}

variable "region" {
  type = string
}

variable "ec2_instance_count" {
  type = number
}

variable "ami_id" {
  type = string
}

variable "top_level_domain_name" {
  type = string
}

variable "customer_domain_prefix" {
  type = set(string)
}

variable "mongodb_public_key" {
  description = "The public API key for MongoDB Atlas"
}
variable "mongodb_private_key" {
  description = "The private API key for MongoDB Atlas"
}
