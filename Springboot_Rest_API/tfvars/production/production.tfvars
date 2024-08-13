environment_name            = "prod"
postfix                     = "01"
project_name                = "fieldassist"
resource_group_name = ""
resource_group_id = ""
aks_vnet_address_space      = ["10.0.0.0/16"]
vm_subnet_address_prefix    = ["10.0.48.0/20"]
azure_rbac_enabled          = true
kubernetes_version          = "1.29.4"
default_node_pool_vm_size   = "Standard_F8s_v2"
default_node_pool_availability_zones = ["1", "2", "3"]
network_dns_service_ip     = "10.2.0.10"
network_service_cidr = "10.2.0.0/24"
location = "centralindia"
default_node_pool_name = "system"
default_node_pool_node_count = "3"

tags = {
    environment = "Production"
    ProjectName = "Field_Assist_Prod"
}

additional_node_pool_name = "user"
additional_node_pool_vm_size = "Standard_D2_v2"
additional_node_pool_node_count = "2"
additional_node_pool_min_count = "2"
additional_node_pool_node_taints = [ "app=fieldassist:NoSchedule" ]
additional_node_pool_node_labels = {
    app = "fieldassist"
}