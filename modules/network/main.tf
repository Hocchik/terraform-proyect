# Módulo network: VPC + subredes públicas + Internet Gateway + tabla de rutas.
# Sin NAT Gateway (cobra por hora): las VMs salen a Internet por el IGW con IP pública.

# Zonas de disponibilidad disponibles en la región (us-east-2a, 2b, 2c).
data "aws_availability_zones" "disponibles" {
  state = "available"
}

locals {
  # Las subredes se calculan a partir del CIDR de la VPC: con un /16 salen /24
  # (10.1.0.0/24, 10.1.1.0/24, ...). Así el usuario solo define un CIDR por sucursal.
  # Con un prefijo mayor a /16 se usan menos bits para no pasarse de /28.
  prefijo_vpc = tonumber(split("/", var.cidr)[1])
  bits_nuevos = min(8, 28 - local.prefijo_vpc)

  zonas = slice(data.aws_availability_zones.disponibles.names, 0, var.cantidad_subredes)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # necesario para que las EC2 reciban nombre DNS público

  tags = merge(var.tags, { Name = "${var.nombre}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.nombre}-igw" })
}

resource "aws_subnet" "publica" {
  count = var.cantidad_subredes

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr, local.bits_nuevos, count.index)
  availability_zone       = local.zonas[count.index]
  map_public_ip_on_launch = true # las VMs necesitan IP pública porque no hay NAT

  tags = merge(var.tags, { Name = "${var.nombre}-publica-${count.index + 1}" })
}

# Una sola tabla de rutas pública compartida por todas las subredes.
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.nombre}-rt-publica" })
}

resource "aws_route_table_association" "publica" {
  count = var.cantidad_subredes

  subnet_id      = aws_subnet.publica[count.index].id
  route_table_id = aws_route_table.publica.id
}

# El security group "default" de la VPC permite tráfico entre sus miembros.
# Lo dejamos sin reglas para que nadie lo use por accidente; las reglas reales
# viven en el módulo firewall. (Buena práctica que además exige checkov.)
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.nombre}-sg-default-bloqueado" })
}
