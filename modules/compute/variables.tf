variable "nombre" {
  description = "Nombre de la sucursal. Las VMs se llaman <nombre>-vm-1, <nombre>-vm-2, ..."
  type        = string
}

variable "subredes_ids" {
  description = "IDs de las subredes donde se reparten las VMs (sale del módulo network). La VM i va a la subred i % cantidad."
  type        = list(string)

  validation {
    condition     = length(var.subredes_ids) > 0
    error_message = "Debe haber al menos una subred."
  }
}

variable "security_group_ids" {
  description = "IDs de los security groups que se asignan a las VMs (sale del módulo firewall)."
  type        = list(string)
}

variable "cantidad_vms" {
  description = "Número de VMs de la sucursal. El caso pide 2."
  type        = number
  default     = 2

  validation {
    condition     = var.cantidad_vms >= 1 && var.cantidad_vms <= 2
    error_message = "Máximo 2 VMs por sucursal (control de costo)."
  }
}

variable "tipo_instancia" {
  description = "Tipo de instancia EC2. Solo se permiten las de capa gratuita."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t2.micro"], var.tipo_instancia)
    error_message = "Solo se permite t3.micro o t2.micro (restricción de costo del proyecto)."
  }
}

variable "key_name" {
  description = "Nombre del key pair de EC2 para entrar por SSH. null = sin llave (la VM se crea pero no se puede entrar por SSH)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags comunes que se aplican a todos los recursos (Proyecto, Sucursal, Entorno)."
  type        = map(string)
  default     = {}
}
