terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
  }
}

provider "mongodbatlas" {
  public_key  = var.MONGODB_PUBLIC_KEY
  private_key = var.MONGODB_PRIVATE_KEY
}

resource "mongodbatlas_cluster" "atlas_cluster" {
  project_id                   = var.atlas_project_id
  name                         = "cluster-atlas"
  num_shards                   = 1
  replication_factor           = 3
  provider_backup_enabled      = true
  auto_scaling_disk_gb_enabled = true
  mongo_db_major_version       = "5.0"

  //Provider settings
  provider_name               = "AWS"
  disk_size_gb                = 10
  provider_disk_iops          = 100
  provider_volume_type        = "STANDARD"
  provider_encrypt_ebs_volume = true
  provider_instance_size_name = "M10"
  provider_region_name        = var.region
}

resource "mongodbatlas_private_endpoint" "atlas_private_endpoint" {
  project_id    = var.atlas_project_id
  provider_name = "AWS"
  region        = var.region

}

resource "aws_vpc_endpoint" "atlas_endpoint_service" {
  vpc_id             = var.vpc_id
  service_name       = mongodbatlas_private_endpoint.atlas_private_endpoint.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
}

resource "mongodbatlas_private_endpoint_interface_link" "atlaseplink" {
  project_id            = mongodbatlas_private_endpoint.atlas_private_endpoint.project_id
  private_link_id       = mongodbatlas_private_endpoint.atlas_private_endpoint.private_link_id
  interface_endpoint_id = aws_vpc_endpoint.atlas_endpoint_service.id
}

