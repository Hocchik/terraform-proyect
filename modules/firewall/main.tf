# Módulo firewall: security group de las VMs de la sucursal.
# Entrada: solo SSH desde los CIDR autorizados. Salida: solo HTTP/HTTPS (actualizaciones de paquetes).
# Cada regla es un recurso propio (aws_vpc_security_group_*_rule): así un cambio manual
# en la consola aparece en el plan como diferencia de UNA regla concreta (útil en la demo de drift).

resource "aws_security_group" "vms" {
  name        = "${var.nombre}-sg-vms"
  description = "VMs de la sucursal ${var.nombre}: SSH restringido y salida web"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.nombre}-sg-vms" })
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = toset(var.cidrs_ssh)

  security_group_id = aws_security_group.vms.id
  description       = "SSH desde IP autorizada"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value

  tags = merge(var.tags, { Name = "${var.nombre}-ssh" })
}

# Salida limitada a 80 y 443: suficiente para "dnf update". El DNS de AWS (VPC+2)
# no pasa por el security group, así que no hace falta abrir el puerto 53.
resource "aws_vpc_security_group_egress_rule" "web" {
  for_each = { http = 80, https = 443 }

  security_group_id = aws_security_group.vms.id
  description       = "Salida ${upper(each.key)} para actualizaciones"
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, { Name = "${var.nombre}-salida-${each.key}" })
}
