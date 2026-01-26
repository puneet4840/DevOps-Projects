
output "primary-sql-server-name" {
  value = azurerm_mssql_server.sql-server-primary.name
}

output "secondary-sql-server-name" {
  value = azurerm_mssql_server.sql-server-secondary.name
}

output "primary-db-name" {
  value = azurerm_mssql_database.primary-db.name
}

output "secondary-db-name" {
  value = azurerm_mssql_database.secondary-db.name
}
