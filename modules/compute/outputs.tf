output "instancias_ids" {
  description = "IDs de las VMs (los usa el módulo monitoring para crear una alarma por VM)."
  value       = aws_instance.vm[*].id
}

output "ips_publicas" {
  description = "IPs públicas de las VMs (para conectarse por SSH)."
  value       = aws_instance.vm[*].public_ip
}

output "ips_privadas" {
  description = "IPs privadas de las VMs dentro de la VPC."
  value       = aws_instance.vm[*].private_ip
}
