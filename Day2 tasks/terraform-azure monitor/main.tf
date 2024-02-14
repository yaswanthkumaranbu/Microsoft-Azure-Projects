terraform {
  required_providers {
    azurerm = {
      version = "2.44.0"
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Alert" {
  name     = "yas-monitoring"
  location = "centralindia"

  tags = {
    "terraform" = "terraform"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "mytg-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.Alert.location
  resource_group_name = azurerm_resource_group.Alert.name

  tags = {
    "terraform" = "terraform"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "mytg-nsg"
  location            = azurerm_resource_group.Alert.location
  resource_group_name = azurerm_resource_group.Alert.name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    "environment" = "Production"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "mytg-subnet"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.Alert.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_storage_account" "example" {
  name                     = "yascentilionstorage"
  resource_group_name      = azurerm_resource_group.Alert.name
  location                 = azurerm_resource_group.Alert.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  tags = {
    environment = "Production"
  }
}

resource "azurerm_data_factory" "example" {
  name                = "mytg-data-factory"
  location            = azurerm_resource_group.Alert.location
  resource_group_name = azurerm_resource_group.Alert.name

  tags = {
    "terraform"    = "terraform"
    "environment"  = "Production"
  }
}

resource "azurerm_data_factory_pipeline" "example" {
  name               = "mytg-data-pipeline"
  resource_group_name = azurerm_resource_group.Alert.name
  data_factory_name  = azurerm_data_factory.example.name
}

resource "azurerm_log_analytics_workspace" "log" {
  name                = "acctest-01"
  location            = azurerm_resource_group.Alert.location
  resource_group_name = azurerm_resource_group.Alert.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_action_group" "example" {
  name                = "CriticalAlertsAction"
  resource_group_name = azurerm_resource_group.Alert.name
  short_name          = "p0action"
  
  email_receiver {
    name                    = "sendtodevops"
    email_address           = "yaswanthkumaranbu@gmail.com"
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "metric_alert" {
  name                = "metricalert"
  resource_group_name = azurerm_resource_group.Alert.name
  scopes              = [azurerm_storage_account.example.id]
  description         = "Action will be triggered when Transactions count is greater than 50."

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 50
  }

  action {
    action_group_id = azurerm_monitor_action_group.example.id  # Use the ID of the action group
  }


  depends_on=[
  azurerm_monitor_action_group.example,
  azurerm_storage_account.example]  
}