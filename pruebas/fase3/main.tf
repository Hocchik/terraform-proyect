# Prueba de una sucursal completa (Fase 3): network + firewall + compute + monitoring.
# State local (no versionado, ver .gitignore). Tras probar: terraform destroy.

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
  # Credenciales: las toma del AWS CLI configurado en tu equipo, nunca del código.
}

variable "mi_ip" {
  description = "Tu IP pública con /32 (ej. 190.12.34.56/32). Va en terraform.tfvars, que NO se versiona."
  type        = string
}

variable "ruta_clave_publica" {
  description = "Ruta a tu llave pública SSH (.pub). Vacío = VMs sin llave (no se podrá entrar por SSH)."
  type        = string
  default     = ""
}

variable "correo" {
  description = "Correo que recibe las alertas de CPU. Va en terraform.tfvars, que NO se versiona."
  type        = string
}

locals {
  sucursal = "prueba-fase3"

  tags = {
    Proyecto = "iac-sucursales"
    Sucursal = local.sucursal
    Entorno  = "practica"
  }
}

module "network" {
  source = "../../modules/network"

  nombre = local.sucursal
  cidr   = "10.99.0.0/16"
  tags   = local.tags
}

module "firewall" {
  source = "../../modules/firewall"

  nombre    = local.sucursal
  vpc_id    = module.network.vpc_id
  cidrs_ssh = [var.mi_ip]
  tags      = local.tags
}

# Solo la llave PÚBLICA sube a AWS; la privada se queda en tu PC.
resource "aws_key_pair" "ssh" {
  count = var.ruta_clave_publica == "" ? 0 : 1

  key_name   = "${local.sucursal}-llave"
  public_key = file(pathexpand(var.ruta_clave_publica))
  tags       = local.tags
}

module "compute" {
  source = "../../modules/compute"

  nombre             = local.sucursal
  subredes_ids       = module.network.subredes_publicas_ids
  security_group_ids = [module.firewall.security_group_id]
  key_name           = one(aws_key_pair.ssh[*].key_name)
  tags               = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  nombre         = local.sucursal
  instancias_ids = module.compute.instancias_ids
  correo         = var.correo
  tags           = local.tags
}

output "ips_publicas" {
  value = module.compute.ips_publicas
}

output "alarmas" {
  value = module.monitoring.alarmas
}
