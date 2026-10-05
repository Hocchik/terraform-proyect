variable "nombre" {
  description = "Nombre de la sucursal. Se usa como prefijo del security group."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se crea el security group (sale del módulo network)."
  type        = string
}

variable "cidrs_ssh" {
  description = "Lista de CIDR autorizados para entrar por SSH (puerto 22). Normalmente solo tu IP pública con /32, ej. [\"190.12.34.56/32\"]."
  type        = list(string)

  validation {
    condition     = length(var.cidrs_ssh) > 0 && alltrue([for c in var.cidrs_ssh : can(cidrhost(c, 0)) && c != "0.0.0.0/0"])
    error_message = "Debe haber al menos un CIDR válido y ninguno puede ser 0.0.0.0/0 (SSH abierto a todo Internet)."
  }
}

variable "tags" {
  description = "Tags comunes que se aplican a todos los recursos (Proyecto, Sucursal, Entorno)."
  type        = map(string)
  default     = {}
}
