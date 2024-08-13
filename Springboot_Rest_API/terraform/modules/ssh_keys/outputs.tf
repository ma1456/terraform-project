output "public_key_data" {
  value = azapi_resource_action.ssh_public_key_gen.output.publicKey
}

output "private_key_data" {
  value = azapi_resource_action.ssh_public_key_gen.output.privateKey
}

output "ssh_public_key_name" {
  value = azapi_resource.ssh_public_key.name
}