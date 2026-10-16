variable "nombre" {
  description = "Nombre de la sucursal. Prefijo del tópico (<nombre>-alertas) y de las alarmas (<nombre>-vm-N-cpu-alta)."
  type        = string
}

variable "instancias_ids" {
  description = "IDs de las VMs a vigilar (sale del módulo compute). Se crea una alarma por cada una, en el mismo orden."
  type        = list(string)
}

variable "correo" {
  description = "Correo que recibe las alertas. null = tópico sin suscriptor (útil en LocalStack o CI). Va en un .tfvars NO versionado."
  type        = string
  default     = null

  validation {
    condition     = var.correo == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.correo))
    error_message = "El correo no tiene un formato válido (ej. nombre@dominio.com)."
  }
}

variable "umbral_cpu" {
  description = "Porcentaje de CPU promedio a partir del cual salta la alarma."
  type        = number
  default     = 80

  validation {
    condition     = var.umbral_cpu > 0 && var.umbral_cpu < 100
    error_message = "El umbral debe estar entre 1 y 99."
  }
}

variable "tags" {
  description = "Tags comunes que se aplican a todos los recursos (Proyecto, Sucursal, Entorno)."
  type        = map(string)
  default     = {}
}
