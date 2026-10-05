variable "nombre" {
  description = "Nombre de la sucursal. Se usa como prefijo en el tag Name de cada recurso (ej. lima-centro)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.nombre))
    error_message = "El nombre solo puede tener minúsculas, números y guiones."
  }
}

variable "cidr" {
  description = "Bloque CIDR de la VPC de la sucursal. Se recomienda un /16 distinto por sucursal (ej. 10.1.0.0/16) para evitar solapamientos."
  type        = string

  validation {
    condition     = try(cidrhost(var.cidr, 0) != "" && tonumber(split("/", var.cidr)[1]) <= 22, false)
    error_message = "Debe ser un CIDR válido con prefijo /22 o mayor (ej. 10.1.0.0/16), para poder dividirlo en subredes /24 o más chicas."
  }
}

variable "cantidad_subredes" {
  description = "Número de subredes públicas a crear, cada una en una zona de disponibilidad distinta. Por defecto 2 (una por VM)."
  type        = number
  default     = 2

  validation {
    condition     = var.cantidad_subredes >= 1 && var.cantidad_subredes <= 3
    error_message = "Debe estar entre 1 y 3 (us-east-2 tiene 3 zonas de disponibilidad)."
  }
}

variable "tags" {
  description = "Tags comunes que se aplican a todos los recursos (Proyecto, Sucursal, Entorno)."
  type        = map(string)
  default     = {}
}
