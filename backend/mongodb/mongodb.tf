terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
  }
}
locals {
  connection_string = {

  }
}

provider "mongodbatlas" {
  public_key  = var.mongodb_public_key
  private_key = var.mongodb_private_key
}

resource "mongodbatlas_teams" "atlas_db_admin_team" {
  org_id    = var.atlas_org_id
  name      = "administrators-${var.env_name}"
  usernames = var.admin_users
}

resource "mongodbatlas_teams" "atlas_db_read_write_team" {
  org_id    = var.atlas_org_id
  name      = "read-write-admin-${var.env_name}"
  usernames = var.read_write_admin_users
}
resource "mongodbatlas_project" "xeniapp_atlas_project" {
  name   = "xeniapp-${var.env_name}"
  org_id = var.atlas_org_id

  teams {
    team_id = mongodbatlas_teams.atlas_db_admin_team.team_id
    role_names = [
    "GROUP_OWNER"]

  }
  teams {
    team_id = mongodbatlas_teams.atlas_db_read_write_team.team_id
    role_names = [
      "GROUP_READ_ONLY",
    "GROUP_DATA_ACCESS_READ_WRITE"]
  }
}
resource "mongodbatlas_cluster" "atlas_cluster" {
  project_id   = mongodbatlas_project.xeniapp_atlas_project.id
  name         = "xeniapp-cluster-${var.env_name}"
  cluster_type = "REPLICASET"
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "US_EAST_1"
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }
  provider_backup_enabled      = true
  auto_scaling_disk_gb_enabled = true
  mongo_db_major_version       = "5.0"

  //Provider settings
  provider_name               = "AWS"
  disk_size_gb                = 10
  provider_disk_iops          = 1000
  provider_volume_type        = "STANDARD"
  provider_instance_size_name = "M10"
  provider_region_name        = "US_EAST_1"
}


resource "mongodbatlas_network_container" "atlas_container" {

  atlas_cidr_block = var.atlas_vpc_cidr
  project_id       = mongodbatlas_project.xeniapp_atlas_project.id
  provider_name    = "AWS"
  region_name      = "US_EAST_1"
}


data "aws_caller_identity" "current" {}

resource "mongodbatlas_network_peering" "aws-atlas" {
  accepter_region_name   = var.region
  project_id             = mongodbatlas_project.xeniapp_atlas_project.id
  container_id           = mongodbatlas_network_container.atlas_container.container_id
  provider_name          = "AWS"
  route_table_cidr_block = var.vpc_cidr
  vpc_id                 = var.vpc_id
  aws_account_id         = data.aws_caller_identity.current.account_id
  depends_on = [
  mongodbatlas_network_container.atlas_container]
}


resource "aws_route" "peeraccess" {
  for_each                  = var.route_table_ids
  route_table_id            = each.value
  destination_cidr_block    = var.atlas_vpc_cidr
  vpc_peering_connection_id = mongodbatlas_network_peering.aws-atlas.connection_id
  depends_on = [
  aws_vpc_peering_connection_accepter.peer]
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = mongodbatlas_network_peering.aws-atlas.connection_id
  auto_accept               = true

}
resource "mongodbatlas_project_ip_access_list" "access_from_private_subnets" {

  project_id = mongodbatlas_project.xeniapp_atlas_project.id
  cidr_block = var.vpc_cidr
  comment    = "Allow connections from VPC"

  depends_on = [
  mongodbatlas_network_peering.aws-atlas]
}


resource "aws_ssm_parameter" "atlas_admin_user_parameter" {
  name = format("/%s/%s/%s/admin-user", var.env_name, mongodbatlas_cluster.atlas_cluster.name, mongodbatlas_project
  .xeniapp_atlas_project.name)
  type  = "String"
  value = mongodbatlas_database_user.admin_user.username
}
resource "aws_secretsmanager_secret" "admin_use_password" {
  name = format("/%s/%s/%s/admin-user-password", var.env_name, mongodbatlas_cluster.atlas_cluster.name,
  mongodbatlas_project.xeniapp_atlas_project.name)
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "admin_user_password_version" {
  secret_id     = aws_secretsmanager_secret.admin_use_password.id
  secret_string = random_password.admin_user_password.result
}

resource "aws_ssm_parameter" "atlas_app_user_parameter" {
  name = format("/%s/%s/%s/app-user", var.env_name, mongodbatlas_cluster.atlas_cluster.name, mongodbatlas_project
  .xeniapp_atlas_project.name)
  type  = "String"
  value = mongodbatlas_database_user.admin_user.username
}
resource "aws_secretsmanager_secret" "app_user_password" {
  name = format("/%s/%s/%s/app-user-password", var.env_name, mongodbatlas_cluster.atlas_cluster.name,
  mongodbatlas_project.xeniapp_atlas_project.name)
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_user_password_version" {
  secret_id     = aws_secretsmanager_secret.app_user_password.id
  secret_string = random_password.app_user_password.result
}

resource "aws_ssm_parameter" "atlas_standard_connection_string" {
  name = format("/%s/%s/%s/connection-string/standard", var.env_name, mongodbatlas_cluster.atlas_cluster.name, mongodbatlas_project
  .xeniapp_atlas_project.name)
  type = "String"
  value = lookup(concat(mongodbatlas_cluster.atlas_cluster.connection_strings, [{
  standard : "" }])[0], "standard")

}

resource "aws_ssm_parameter" "atlas_standard_srv_connection_string" {
  name = format("/%s/%s/%s/connection-string/standard_srv", var.env_name, mongodbatlas_cluster.atlas_cluster.name, mongodbatlas_project
  .xeniapp_atlas_project.name)
  type = "String"
  value = lookup(concat(mongodbatlas_cluster.atlas_cluster.connection_strings, [{
  standard_srv : "" }])[0], "standard_srv")

}
