variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-2"
}

variable "db_username" {
  description = "Usuario maestro de la base de datos RDS"
  type        = string
  default     = "icesi_admin"
}

variable "db_password" {
  description = "Contraseña maestra de la base de datos RDS"
  type        = string
  sensitive   = true
}

variable "dev_my_ip" {
  description = "Tu IP pública para acceso temporal a RDS desde el laptop (dejar vacío en producción)"
  type        = string
  default     = ""
}