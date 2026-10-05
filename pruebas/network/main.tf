# Prueba aislada del módulo network (Fase 1).
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

locals {
  sucursal = "prueba-network"

  tags = {
    Proyecto = "iac-sucursales"
    Sucursal = local.sucursal
    Entorno  = "practica"
  }
}

module "network" {
  source = "../../modules/network"

  nombre = local.sucursal
  cidr   = "10.99.0.0/16" # rango reservado para pruebas, no choca con sucursales reales
  tags   = local.tags
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "subredes" {
  value = module.network.subredes_publicas_ids
}

output "zonas" {
  value = module.network.zonas
}
