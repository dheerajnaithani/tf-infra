resource "random_password" "admin_user_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
resource "random_password" "app_user_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "mongodbatlas_database_user" "admin_user" {
  username           = "admin-${var.env_name}"
  password           = random_password.admin_user_password.result
  project_id         = mongodbatlas_project.xeniapp_atlas_project.id
  auth_database_name = "admin"

  roles {
    role_name     = "atlasAdmin"
    database_name = "admin"
  }
  labels {
    key   = "Name"
    value = "admin-${var.env_name}"
  }

  scopes {
    name = mongodbatlas_cluster.atlas_cluster.name
    type = "CLUSTER"
  }
}


resource "mongodbatlas_database_user" "app_user" {
  username           = "app-user-${var.env_name}"
  password           = random_password.app_user_password.result
  project_id         = mongodbatlas_project.xeniapp_atlas_project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "xeni-db-${var.env_name}"
  }
  labels {
    key   = "Name"
    value = "app-user-${var.env_name}"
  }

  scopes {
    name = mongodbatlas_cluster.atlas_cluster.name
    type = "CLUSTER"
  }
}

