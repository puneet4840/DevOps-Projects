module "resource-group" {
  source = "./modules/resource-group"

  resource-group-name = "mera-rg-central-india"
  resource-group-location = "Central India"
}

# This module will create App Service.
module "app-service-central-india" {

  source = "./modules/app-service"

  app-service-plan-name = "mera-app-service-plan-central-india"
  app-service-name = "mera-app-service-central-india"
  app-service-resource-group-name = module.resource-group.resource-group-name
  app-service-location = "Central India"
  app-service-plan-location = "Central India"
  sku_name = "B1"
}

# This module will create App Service.
module "app-service-south-india" {

  source = "./modules/app-service"

  app-service-plan-name = "mera-app-service-plan-south-india"
  app-service-name = "mera-app-service-south-india"
  app-service-location = "South India"
  app-service-plan-location = "South India"
  app-service-resource-group-name = module.resource-group.resource-group-name
  sku_name = "B1"
}

# This module will create Front Door.
module "front-door" {

  source = "./modules/front-door"

  front-door-profile-name = "mera-front-door"
  resource_group_name = module.resource-group.resource-group-name
  frond-door-endpoint-name = "mera-app"
  front-door-origin-name = "backend-pool"
  front-door-primary-origin-name = "central-india-app-service"
  primary-origin-hostname = module.app-service-central-india.default_hostname
  primary-origin-host-header = module.app-service-central-india.default_hostname
  front-door-secondary-origin-name = "south-india-app-service"
  secondary-origin-host-name = module.app-service-south-india.default_hostname
  secondary-origin-host-header = module.app-service-south-india.default_hostname

}


# This module will create Sql Server and Database.
module "sql-server-and-database-wit-geo-replication" {
  source = "./modules/sql-server"
  
  # Both SQL Server Resource Group Name
  resource-group-name = module.resource-group.resource-group-name.name
  
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