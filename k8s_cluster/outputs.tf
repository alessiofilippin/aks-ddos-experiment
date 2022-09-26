
output "kube_host" {
  value     = azurerm_kubernetes_cluster.this.kube_config.0.host
  sensitive = true
}

output "kube_username" {
  value = azurerm_kubernetes_cluster.this.kube_config.0.username
  sensitive = true
}

output "kube_password" {
  value = azurerm_kubernetes_cluster.this.kube_config.0.password
  sensitive = true
}

output "kube_cert" {
  value = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
  sensitive = true
}

output "kube_key" {
  value = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_key)
  sensitive = true
}

output "kube_ca_cert" {
  value = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
  sensitive = true
}