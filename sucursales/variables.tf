# Valores comunes a todas las sucursales. En tu PC van en terraform.tfvars (NO versionado);
# en GitHub Actions llegarán como variables/secretos del environment (Fase 6).

variable "cidrs_ssh" {
  description = "CIDR autorizados para SSH en todas las sucursales (ej. [\"190.12.34.56/32\"])."
  type        = list(string)
}

variable "clave_publica_ssh" {
  description = "Contenido de la llave pública SSH (línea 'ssh-ed25519 AAAA...'). null = VMs sin llave."
  type        = string
  default     = null
}

variable "correo" {
  description = "Correo que recibe las alertas de CPU. null = tópicos sin suscriptor."
  type        = string
  default     = null
}
