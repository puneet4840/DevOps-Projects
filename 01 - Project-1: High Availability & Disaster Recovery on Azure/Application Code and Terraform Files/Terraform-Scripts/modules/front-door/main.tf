resource "azurerm_cdn_frontdoor_profile" "afd" {
  name = var.front-door-profile-name
  resource_group_name = var.resource_group_name
  sku_name = "Standard_AzureFrontDoor"
}

# Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "afd-endpoint" {
  name = var.frond-door-endpoint-name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
}

# Backend Pool
resource "azurerm_cdn_frontdoor_origin_group" "afd-origin-group" {
  name = var.front-door-origin-name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  

  health_probe {
    interval_in_seconds = 30
    path = "/health"
    protocol = "Https"
    request_type = "GET"
  }

  load_balancing {
    sample_size = 4
    successful_samples_required = 3
  }

}

# Backend-1

resource "azurerm_cdn_frontdoor_origin" "primary-origin" {
  name = var.front-door-primary-origin-name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.afd-origin-group.id
  host_name = var.primary-origin-hostname
  origin_host_header = var.primary-origin-host-header

  http_port = 80
  https_port = 443

  priority = 1
  weight = 1000

  certificate_name_check_enabled = false
}

# Backend-2

resource "azurerm_cdn_frontdoor_origin" "secondary-origin" {
  name = var.front-door-secondary-origin-name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.afd-origin-group.id
  host_name = var.secondary-origin-host-name

  origin_host_header = var.secondary-origin-host-header

  http_port = 80
  https_port = 443

  priority = 2
  weight = 1000

  certificate_name_check_enabled = false

}


resource "azurerm_cdn_frontdoor_route" "route" {
  name = "route-all-traffic"
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.afd-endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.afd-origin-group.id
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.primary-origin.id, azurerm_cdn_frontdoor_origin.secondary-origin.id]

  supported_protocols = ["Http", "Https"]
  patterns_to_match = ["/*"]
  forwarding_protocol = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true
  enabled = true

  depends_on = [ azurerm_cdn_frontdoor_origin_group.afd-origin-group, azurerm_cdn_frontdoor_origin.primary-origin, azurerm_cdn_frontdoor_origin.secondary-origin ]
}