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

variable "MONGODB_PUBLIC_KEY" {
  description = "The public API key for MongoDB Atlas"
}
variable "MONGODB_PRIVATE_KEY" {
  description = "The private API key for MongoDB Atlas"
}
