#Parte 7
output "website_endpoint" {
  description = "El endpoint público del sitio web estático S3."
  # Este output es para la configuración del sitio web
  value       = aws_s3_bucket_website_configuration.website_config.website_endpoint 
}

output "website_url" {
  description = "La URL completa del sitio web estático S3 (usando la región)."
  # Cambia website_domain (obsoleto) por website_endpoint
  value       = aws_s3_bucket.mi_bucket_ejemplo.website_endpoint
}