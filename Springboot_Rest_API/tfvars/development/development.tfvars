environment_name            = "dev"
postfix                     = "02"
project_name                = "fieldassist"
resource_group_name         = "Field_Assist_dev"
resource_group_id           = "/subscriptions/82ed337b-57eb-4385-b366-25db8fce0a92/resourceGroups/Field_Assist_dev"  ###### az group show --name Field_Assist_dev --query id --output tsv
aks_vnet_address_space      = ["10.0.0.0/16"]
vm_subnet_address_prefix    = ["10.0.48.0/20"]
azure_rbac_enabled          = true
kubernetes_version          = "1.29.4"
default_node_pool_vm_size   = "Standard_DS2_v2"
default_node_pool_availability_zones = ["1", "2", "3"]
network_dns_service_ip      = "10.2.0.10"
network_service_cidr        = "10.2.0.0/24"
location                    = "centralindia"
default_node_pool_name      = "system"
default_node_pool_node_count = "2"

tags = {
    environment = "developemnt"
    ProjectName = "Field_Assist_dev"
}

# additional_node_pool_name   = "user"
# additional_node_pool_vm_size = "Standard_F8s_v2"
# additional_node_pool_node_count = "2"