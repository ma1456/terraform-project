variable "name" {
  description = "(Required) Specifies the name of the SSH Key"
  type        = string
}

variable "resource_group_name" {
  description = "(Required) Specifies the resource group name of the key vault."
  type        = string
}

variable "location" {
  description = "(Required) Specifies the location where the key vault will be deployed."
  type        = string
}

variable "resource_group_id" {
  description = "(Required) Specifies the resource group Id."
  type        = string
}
