environment_name            = "preprod"
postfix                     = "01"
project_name                = "fieldassist"
resource_group_name         = "Field_Assist_PreProd01"
resource_group_id           = "/subscriptions/c3d7eec8-0044-4040-b98f-b66627cfb27a/resourceGroups/Field_Assist_PreProd01"
aks_vnet_address_space      = ["10.0.0.0/16"]
vm_subnet_address_prefix    = ["10.0.48.0/20"]
azure_rbac_enabled          = true
kubernetes_version          = "1.29.4"
default_node_pool_vm_size   = "Standard_DS2_v2"
http_application_routing_enabled = false
default_node_pool_availability_zones = ["1", "2", "3"]
network_dns_service_ip      = "10.2.0.10"
network_service_cidr        = "10.2.0.0/24"
location                    = "centralindia"
default_node_pool_name      = "system"
default_node_pool_node_count = "3"
default_node_pool_min_count = "2"

tags = {
    environment = "Pre-Production"
    ProjectName = "Field_Assist_Pre-Prod"
}

additional_node_pool_name = "user"
additional_node_pool_vm_size = "Standard_DS2_v2"
additional_node_pool_node_count = "2"