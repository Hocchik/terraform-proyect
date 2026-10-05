output "vpc_id" {
  description = "ID de la VPC de la sucursal (lo usa el módulo firewall)."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "subredes_publicas_ids" {
  description = "Lista de IDs de las subredes públicas (las usa el módulo compute para ubicar las VMs)."
  value       = aws_subnet.publica[*].id
}

output "zonas" {
  description = "Zonas de disponibilidad usadas, en el mismo orden que las subredes."
  value       = aws_subnet.publica[*].availability_zone
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway."
  value       = aws_internet_gateway.this.id
}
