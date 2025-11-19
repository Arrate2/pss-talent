variable "aws_region" {
  description = "La región de AWS donde se desplegará la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "El rango CIDR para la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de rangos CIDR para las subredes públicas (debe ser 2)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  description = "Tipo de instancia EC2 a usar (t2.micro es elegible para la capa gratuita)."
  type        = string
  default     = "t3.small"
}

variable "db_name" {
  description = "Name for the RDS PostgreSQL database (e.g., wordpressdb)."
  type        = string
  default     = "wordpressdb"
}

variable "db_user" {
  description = "Username for the RDS PostgreSQL database."
  type        = string
  sensitive   = true # Marca como sensible para evitar que se muestre en el output
}

variable "db_pass" {
  description = "Password for the RDS PostgreSQL database."
  type        = string
  sensitive   = true
}

variable "wordpress_public_key" {
  type        = string
  description = "Public SSH key used for the WordPress EC2 instances."
}

