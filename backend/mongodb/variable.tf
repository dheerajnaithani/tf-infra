variable "mongodb_public_key" {
  description = "The public API key for MongoDB Atlas"
}
variable "mongodb_private_key" {
  description = "The private API key for MongoDB Atlas"
}

variable "env_name" {
  type = string
}
variable "admin_users" {

}

variable "read_write_admin_users" {

}

variable "region" {

  description = "Atlas Region"
}

variable "atlas_org_id" {
  description = "Atlas Org ID"
}

variable "subnet_ids" {

}

variable "vpc_id" {

}

variable "security_group_ids" {

}

variable "atlas_vpc_cidr" {
  description = "Atlas CIDR"

}

variable "vpc_cidr" {

}

variable "route_table_ids" {

}
