terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.50.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
  }
}

locals {
  storage_account_prefix = "boot"
  route_table_name       = "DefaultRouteTable"
  route_name             = "RouteToAzureFirewall"
}

data "azurerm_client_config" "current" {
}

module "log_analytics_workspace" {
  source              = "./modules/log_analytics"
  name                = "log-${var.project_name}-${var.environment_name}-${var.postfix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  solution_plan_map   = var.solution_plan_map
}

module "hub_network" {
  source                     = "./modules/virtual_network"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  vnet_name                  = "aks-hubvnet-${var.project_name}-${var.environment_name}-${var.postfix}"
  address_space              = var.hub_address_space
  tags                       = var.tags
  log_analytics_workspace_id = module.log_analytics_workspace.id

  subnets = [
    {
      name : "AzureFirewallSubnet"
      address_prefixes : var.hub_firewall_subnet_address_prefix
      private_endpoint_network_policies_enabled : true
      private_link_service_network_policies_enabled : false
    },
    {
      name : "AzureBastionSubnet"
      address_prefixes : var.hub_bastion_subnet_address_prefix
      private_endpoint_network_policies_enabled : true
      private_link_service_network_policies_enabled : false
    }
  ]
}

module "aks_network" {
  source                     = "./modules/virtual_network"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  vnet_name                  = "aks-vnet-${var.project_name}-${var.environment_name}-${var.postfix}"
  address_space              = var.aks_vnet_address_space
  log_analytics_workspace_id = module.log_analytics_workspace.id

  subnets = [
    {
      name : var.default_node_pool_subnet_name
      address_prefixes : var.default_node_pool_subnet_address_prefix
      private_endpoint_network_policies_enabled : true
      private_link_service_network_policies_enabled : false
    },
    {
      name : var.additional_node_pool_subnet_name
      address_prefixes : var.additional_node_pool_subnet_address_prefix
      private_endpoint_network_policies_enabled : true
      private_link_service_network_policies_enabled : false
    },
    {
      name : var.pod_subnet_name
      address_prefixes : var.pod_subnet_address_prefix
      private_endpoint_network_policies_enabled : true
      private_link_service_network_policies_enabled : false
    },
    {
      name : var.vm_subnet_name
      address_prefixes : var.vm_subnet_address_prefix
      private_endpoint_network_policies_enabled : true
      private_link_service_network_policies_enabled : false
    }
  ]
}

module "vnet_peering" {
  source              = "./modules/virtual_network_peering"
  vnet_1_name         = "aks-hubvnet-${var.project_name}-${var.environment_name}-${var.postfix}"
  vnet_1_id           = module.hub_network.vnet_id
  vnet_1_rg           = var.resource_group_name
  vnet_2_name         = "aks-vnet-${var.project_name}-${var.environment_name}-${var.postfix}"
  vnet_2_id           = module.aks_network.vnet_id
  vnet_2_rg           = var.resource_group_name
  peering_name_1_to_2 = "aks-hubvnet-${var.project_name}-${var.environment_name}-${var.postfix}Toaks-vnet-${var.project_name}-${var.environment_name}-${var.postfix}"
  peering_name_2_to_1 = "aks-vnet-${var.project_name}-${var.environment_name}-${var.postfix}Toaks-hubvnet-${var.project_name}-${var.environment_name}-${var.postfix}"
}

module "firewall" {
  source                     = "./modules/firewall"
  name                       = "firewall-${var.project_name}-${var.environment_name}-${var.postfix}"
  firewall_pip_name          = "firewall-${var.project_name}-${var.environment_name}-pip-${var.postfix}"
  firewall_policy_name       = "firewall-${var.project_name}-${var.environment_name}-policy-${var.postfix}"
  resource_group_name        = var.resource_group_name
  zones                      = var.firewall_zones
  threat_intel_mode          = var.firewall_threat_intel_mode
  location                   = var.location
  sku_name                   = var.firewall_sku_name
  sku_tier                   = var.firewall_sku_tier
  pip_name                   = "firewall-${var.project_name}-${var.environment_name}-pip-${var.postfix}"
  subnet_id                  = module.hub_network.subnet_ids["AzureFirewallSubnet"]
  log_analytics_workspace_id = module.log_analytics_workspace.id
}

module "routetable" {
  source              = "./modules/route_table"
  resource_group_name = var.resource_group_name
  location            = var.location
  route_table_name    = "rt-${var.project_name}-${var.environment_name}-${var.postfix}"
  route_name          = "route-${var.project_name}-${var.environment_name}-${var.postfix}"
  firewall_private_ip = module.firewall.private_ip_address
  subnets_to_associate = {
    (var.default_node_pool_subnet_name) = {
      subscription_id      = data.azurerm_client_config.current.subscription_id
      resource_group_name  = var.resource_group_name
      virtual_network_name = module.aks_network.name
    }
    (var.additional_node_pool_subnet_name) = {
      subscription_id      = data.azurerm_client_config.current.subscription_id
      resource_group_name  = var.resource_group_name
      virtual_network_name = module.aks_network.name
    }
  }
}

module "container_registry" {
  source                     = "./modules/container_registry"
  name                       = "cr${var.project_name}${var.environment_name}${var.postfix}"
  acr_identity_name          = "cr${var.project_name}${var.environment_name}${var.postfix}identity"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  sku                        = var.acr_sku
  admin_enabled              = var.acr_admin_enabled
  georeplication_locations   = var.acr_georeplication_locations
  log_analytics_workspace_id = module.log_analytics_workspace.id
}

module "aks_cluster" {
  source                               = "./modules/aks"
  name                                 = "aks-${var.project_name}-${var.environment_name}-${var.postfix}"
  aks_identity_name                    = "aks-${var.project_name}-${var.environment_name}-${var.postfix}-identity"
  location                             = var.location
  resource_group_name                  = var.resource_group_name
  resource_group_id                    = var.resource_group_id
  kubernetes_version                   = var.kubernetes_version
  dns_prefix                           = lower("aks-${var.project_name}-${var.environment_name}-${var.postfix}")
  private_cluster_enabled              = true
  automatic_channel_upgrade            = var.automatic_channel_upgrade
  sku_tier                             = var.sku_tier
  default_node_pool_name               = var.default_node_pool_name
  default_node_pool_vm_size            = var.default_node_pool_vm_size
  vnet_subnet_id                       = module.aks_network.subnet_ids[var.default_node_pool_subnet_name]
  default_node_pool_availability_zones = var.default_node_pool_availability_zones
  # default_node_pool_node_labels            = var.default_node_pool_node_labels
  # default_node_pool_node_taints            = var.default_node_pool_node_taints
  default_node_pool_enable_auto_scaling    = var.default_node_pool_enable_auto_scaling
  default_node_pool_enable_host_encryption = var.default_node_pool_enable_host_encryption
  default_node_pool_enable_node_public_ip  = var.default_node_pool_enable_node_public_ip
  default_node_pool_max_pods               = var.default_node_pool_max_pods
  default_node_pool_max_count              = var.default_node_pool_max_count
  default_node_pool_min_count              = var.default_node_pool_min_count
  default_node_pool_node_count             = var.default_node_pool_node_count
  default_node_pool_os_disk_type           = var.default_node_pool_os_disk_type
  tags                                     = var.tags
  network_dns_service_ip                   = var.network_dns_service_ip
  network_plugin                           = var.network_plugin
  outbound_type                            = "userDefinedRouting"
  network_service_cidr                     = var.network_service_cidr
  log_analytics_workspace_id               = module.log_analytics_workspace.id
  role_based_access_control_enabled        = var.role_based_access_control_enabled
  tenant_id                                = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids                   = var.admin_group_object_ids
  azure_rbac_enabled                       = var.azure_rbac_enabled
  admin_username                           = var.admin_username
  ssh_public_key                           = module.ssh_key.public_key_data
  keda_enabled                             = var.keda_enabled
  vertical_pod_autoscaler_enabled          = var.vertical_pod_autoscaler_enabled
  workload_identity_enabled                = var.workload_identity_enabled
  oidc_issuer_enabled                      = var.oidc_issuer_enabled
  open_service_mesh_enabled                = var.open_service_mesh_enabled
  image_cleaner_enabled                    = var.image_cleaner_enabled
  azure_policy_enabled                     = var.azure_policy_enabled
  http_application_routing_enabled         = var.http_application_routing_enabled

  depends_on = [
    module.routetable,
    module.ssh_key
  ]
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                            = var.resource_group_id
  role_definition_name             = "Network Contributor"
  principal_id                     = module.aks_cluster.aks_identity_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acr_pull" {
  role_definition_name             = "AcrPull"
  scope                            = module.container_registry.id
  principal_id                     = module.aks_cluster.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

module "storage_account" {
  source                 = "./modules/storage_account"
  name                   = lower("sa${var.project_name}${var.environment_name}")
  location               = var.location
  resource_group_name    = var.resource_group_name
  account_kind           = var.storage_account_kind
  account_tier           = var.storage_account_tier
  replication_type       = var.storage_account_replication_type
  storage_container_name = "container-${var.project_name}-${var.environment_name}-${var.postfix}"
  script_name            = "configure-jumpbox-vm.sh"
  script_location        = "scripts/configure-jumpbox-vm.sh"
}
module "virtual_machine" {
  source                       = "./modules/virtual_machine"
  name                         = "vm-jumpbox-${var.environment_name}-${var.postfix}"
  vm_nsg_name                  = "vm-jumpbox-${var.environment_name}-nsg-${var.postfix}"
  public_ip_name               = "vm-jumpbox-${var.environment_name}-pip-${var.postfix}"
  vm_disk_name                 = "vm-jumpbox-${var.environment_name}-disk-${var.postfix}"
  size                         = var.vm_size
  location                     = var.location
  public_ip                    = var.vm_public_ip
  vm_user                      = var.admin_username
  # admin_password = var.admin_password
  admin_ssh_public_key         = module.ssh_key.public_key_data
  os_disk_image                = var.vm_os_disk_image
  domain_name_label            = "${var.project_name}-${var.environment_name}-${var.postfix}vm"
  resource_group_name          = var.resource_group_name
  subnet_id                    = module.aks_network.subnet_ids[var.vm_subnet_name]
  os_disk_storage_account_type = var.vm_os_disk_storage_account_type
  # boot_diagnostics_storage_account    = module.storage_account.primary_blob_endpoint
  log_analytics_workspace_id          = module.log_analytics_workspace.workspace_id
  log_analytics_workspace_key         = module.log_analytics_workspace.primary_shared_key
  log_analytics_workspace_resource_id = module.log_analytics_workspace.id
  script_storage_account_name         = module.storage_account.name
  script_storage_account_key          = module.storage_account.primary_access_key
  container_name                      = module.storage_account.container_name
  script_name                         = var.script_name

  depends_on = [
    module.ssh_key,
    module.storage_account
  ]
}

module "node_pool" {
  source                 = "./modules/node_pool"
  resource_group_name    = var.resource_group_name
  kubernetes_cluster_id  = module.aks_cluster.id
  name                   = var.additional_node_pool_name
  vm_size                = var.additional_node_pool_vm_size
  mode                   = var.additional_node_pool_mode
  node_labels            = var.additional_node_pool_node_labels
  node_taints            = var.additional_node_pool_node_taints
  availability_zones     = var.additional_node_pool_availability_zones
  vnet_subnet_id         = module.aks_network.subnet_ids[var.additional_node_pool_subnet_name]
  enable_auto_scaling    = var.additional_node_pool_enable_auto_scaling
  enable_host_encryption = var.additional_node_pool_enable_host_encryption
  enable_node_public_ip  = var.additional_node_pool_enable_node_public_ip
  orchestrator_version   = var.kubernetes_version
  max_pods               = var.additional_node_pool_max_pods
  max_count              = var.additional_node_pool_max_count
  min_count              = var.additional_node_pool_min_count
  node_count             = var.additional_node_pool_node_count
  os_type                = var.additional_node_pool_os_type
  os_disk_type = var.additional_node_pool_os_disk_type
  priority               = var.additional_node_pool_priority
  tags                   = var.tags

  depends_on = [module.routetable]
}

module "ssh_key" {
  source              = "./modules/ssh_keys"
  resource_group_id   = var.resource_group_id
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "vm-sshkey-${var.project_name}-${var.environment_name}-${var.postfix}"
}