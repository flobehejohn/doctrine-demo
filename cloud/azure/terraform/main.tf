resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = replace("${local.name}acr","-","")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${local.name}-dns"

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = "Standard_B2s"
  }

  identity { type = "SystemAssigned" }
  network_profile { network_plugin = "kubenet" }
}

output "acr_login_server" { value = azurerm_container_registry.acr.login_server }
output "aks_name"         { value = azurerm_kubernetes_cluster.aks.name }
