output "grupo" {
  description = "Grupo (workspace) aplicado."
  value       = local.grupo

  # Evita aplicar en un workspace que no es un grupo (ej. "default" o un nombre mal escrito).
  precondition {
    condition     = length(local.sucursales) > 0
    error_message = "El workspace \"${terraform.workspace}\" no es un grupo de sucursales.yaml. Usa: terraform workspace select <grupo>"
  }
}

output "ips_publicas" {
  description = "IPs públicas de las VMs de cada sucursal del grupo."
  value       = { for nombre, c in module.compute : nombre => c.ips_publicas }
}

output "alarmas" {
  description = "Alarmas de CPU de cada sucursal del grupo."
  value       = { for nombre, m in module.monitoring : nombre => m.alarmas }
}
