
output "atlasclusterstring" {
  value = mongodbatlas_cluster.atlas_cluster.connection_strings
}

output "admin_user" {
  value = mongodbatlas_database_user.admin_user.username
}
output "app_user" {
  value = mongodbatlas_database_user.app_user.username
}

