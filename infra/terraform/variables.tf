variable "aws_region" {
  description = "AWS region donde desplegar"
  type        = string
  default     = "eu-west-1"
}

variable "image_tag" {
  description = "Tag de la imagen Docker a desplegar (SHA del commit)"
  type        = string
  default     = "latest"
}

variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
  default     = "ai-agent"
}
