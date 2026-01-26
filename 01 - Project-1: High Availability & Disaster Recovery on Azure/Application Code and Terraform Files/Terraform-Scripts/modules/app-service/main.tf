resource "azurerm_service_plan" "app-service-plan-local" {
  name                = var.app-service-plan-name
  resource_group_name = var.app-service-resource-group-name
  location            = var.app-service-plan-location
  os_type             = "Linux"
  sku_name            = var.sku_name
}


resource "azurerm_linux_web_app" "app-service-local" {
  name                = var.app-service-name
  resource_group_name = var.app-service-resource-group-name
  location            = var.app-service-location
  service_plan_id     = azurerm_service_plan.app-service-plan-local.id

  site_config {
    always_on = false
    application_stack {
      python_version = "3.11"
    }
  }
}