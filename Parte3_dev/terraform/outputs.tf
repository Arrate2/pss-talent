output "web_public_ip" {
  description = "La IP pública del servidor web (para acceder a WordPress)."
  value       = aws_instance.webserver.public_ip
}

output "db_public_ip" {
  description = "La IP pública del servidor de base de datos."
  value       = aws_instance.dbserver.public_ip
}
