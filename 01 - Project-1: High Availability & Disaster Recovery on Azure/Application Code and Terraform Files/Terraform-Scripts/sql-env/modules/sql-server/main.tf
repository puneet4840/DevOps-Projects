
# Primary SQL Server (Central India)
resource "azurerm_mssql_server" "sql-server-primary" {
  name = var.primary-sql-server-name
  resource_group_name = var.resource-group-name
  location = var.primary-sql-server-location
  version = "12.0"
  administrator_login = var.primary-admin-login
  administrator_login_password = var.primary-admin-password
}

# Secondary SQL Server (South India)
resource "azurerm_mssql_server" "sql-server-secondary" {
  name = var.secondary-sql-server-name
  resource_group_name = var.resource-group-name
  location = var.secondary-sql-server-location
  version = "12.0"
  administrator_login = var.secondary-admin-login
  administrator_login_password = var.secondary-admin-password
}


# Primary Database

resource "azurerm_mssql_database" "primary-db" {
  name = var.primary-db-name
  server_id = azurerm_mssql_server.sql-server-primary.id
  sku_name = "S1"
}

# Secondary Database

resource "azurerm_mssql_database" "secondary-db" {
  name = var.secondary-db-name
  server_id = azurerm_mssql_server.sql-server-secondary.id
  creation_source_database_id = azurerm_mssql_database.primary-db.id
  create_mode = "Secondary"
  sku_name = "S1"
}


/*
resource "azurerm_mssql_server" "sql-server" {
  name = var.sql-server-name
  resource_group_name = var.sql-server-name
  location = var.sql-server-location
  version = "12.0"
  administrator_login = var.admin-login
  administrator_login_password = var.admin-login-password
}


resource "azurerm_mssql_database" "sql-database" {
  name = var.sql-database-name
  server_id = var.server-id
  creation_source_database_id = var.creation_source_database_id
}
*/