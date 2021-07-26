output "atlasclusterstring" {
  value = mongodbatlas_cluster.atlas_cluster.connection_strings
}
output "plstring" {
  value = lookup(mongodbatlas_cluster.atlas_cluster.connection_strings[0].aws_private_link_srv, aws_vpc_endpoint.atlas_endpoint_service.id)
}
