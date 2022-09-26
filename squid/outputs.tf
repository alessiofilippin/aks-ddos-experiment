
output "global_lb_ip" {
  value  = azurerm_public_ip.pub_ip_lb.ip_address
}