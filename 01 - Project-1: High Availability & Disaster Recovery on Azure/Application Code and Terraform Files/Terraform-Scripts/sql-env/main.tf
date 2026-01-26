data "azurerm_resource_group" "resource-group" {
  name = "mera-rg-central-india"
}

# This module will create Sql Server and Database.
module "sql-server-and-database-wit-geo-replication" {
  source = "./modules/sql-server"
  
  # Both SQL Server Resource Group Name
  resource-group-name = data.azurerm_resource_group.resource-group.name
  
  # Primary SQL Server
  primary-sql-server-name = "sql-server-primary"
  primary-sql-server-location = "Central India"
  primary-admin-login = "puneet"
  primary-admin-password = "welcome@123"

  # Secondary SQL Server
  secondary-sql-server-name = "sql-server-secondary"
  secondary-sql-server-location = "South India"
  secondary-admin-login = "puneet"
  secondary-admin-password = "welcome@123"

  # Primary DB
  primary-db-name = "primary-database"

  # Secondary DB
  secondary-db-name = "secondary-database"
}