output "security_group_id" {
  description = "ID del security group de las VMs (lo usa el módulo compute)."
  value       = aws_security_group.vms.id
}

output "security_group_nombre" {
  description = "Nombre del security group (para ubicarlo rápido en la consola, ej. en la demo de drift)."
  value       = aws_security_group.vms.name
}
