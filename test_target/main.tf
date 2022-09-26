resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-target-rg"
  location = var.location
}

resource "azurerm_service_plan" "this" {
  name                = "${var.name_prefix}-target-plan"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name_prefix}-target-log"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "this" {
  name                = "${var.name_prefix}-appinsights"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
}

resource "azurerm_linux_web_app" "this" {
  name                = "${var.name_prefix}-target-app"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_service_plan.this.location
  service_plan_id     = azurerm_service_plan.this.id

  site_config {
    always_on = true

    application_stack {
      docker_image     = "jetty"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"                 = "https://index.docker.io/v1"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = azurerm_application_insights.this.connection_string
    "APPINSIGHTS_PROFILERFEATURE_VERSION"        = "1.0.0"
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"        = "1.0.0"
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = azurerm_application_insights.this.instrumentation_key
    "WEBSITES_PORT"                              = "8080"
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diagnostic-to-${azurerm_log_analytics_workspace.this.name}"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  log {
    category = "AppServiceHTTPLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 180
    }
  }

  log {
    category = "AppServicePlatformLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 180
    }
  }

  log {
    category = "AppServiceConsoleLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 180
    }
  }

  log {
    category = "AppServiceAppLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 180
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 180
    }
  }
}

