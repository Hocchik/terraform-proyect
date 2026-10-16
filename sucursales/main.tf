# Raíz multi-sucursal: crea todas las sucursales de UN grupo, leídas de sucursales.yaml.
# El grupo es el workspace de Terraform (terraform workspace select <grupo>),
# así cada grupo tiene su propio state y no se puede aplicar un grupo sobre el state de otro.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  # Credenciales: AWS CLI en tu equipo; en GitHub Actions, OIDC (Fase 6). Nunca en el código.
}

locals {
  grupo = terraform.workspace

  # Todas las sucursales del archivo, indexadas por nombre (un nombre repetido da error).
  todas = { for s in yamldecode(file("${path.module}/sucursales.yaml")).sucursales : s.nombre => s }

  # Solo las del grupo del workspace actual.
  sucursales = { for nombre, s in local.todas : nombre => s if s.grupo == local.grupo }

  tags = {
    for nombre, s in local.sucursales : nombre => {
      Proyecto = "iac-sucursales"
      Sucursal = nombre
      Grupo    = s.grupo
      Entorno  = "practica"
    }
  }
}

# Una llave por grupo (solo la PÚBLICA sube a AWS). Sin llave = VMs sin acceso SSH.
resource "aws_key_pair" "ssh" {
  count = var.clave_publica_ssh == null ? 0 : 1

  key_name   = "iac-sucursales-${local.grupo}"
  public_key = var.clave_publica_ssh

  tags = {
    Proyecto = "iac-sucursales"
    Sucursal = "grupo-${local.grupo}"
    Grupo    = local.grupo
    Entorno  = "practica"
  }
}

module "network" {
  source   = "../modules/network"
  for_each = local.sucursales

  nombre = each.key
  cidr   = each.value.cidr
  tags   = local.tags[each.key]
}

module "firewall" {
  source   = "../modules/firewall"
  for_each = local.sucursales

  nombre    = each.key
  vpc_id    = module.network[each.key].vpc_id
  cidrs_ssh = var.cidrs_ssh
  tags      = local.tags[each.key]
}

module "compute" {
  source   = "../modules/compute"
  for_each = local.sucursales

  nombre             = each.key
  subredes_ids       = module.network[each.key].subredes_publicas_ids
  security_group_ids = [module.firewall[each.key].security_group_id]
  key_name           = one(aws_key_pair.ssh[*].key_name)
  tags               = local.tags[each.key]
}

module "monitoring" {
  source   = "../modules/monitoring"
  for_each = local.sucursales

  nombre         = each.key
  instancias_ids = module.compute[each.key].instancias_ids
  correo         = var.correo
  tags           = local.tags[each.key]
}
