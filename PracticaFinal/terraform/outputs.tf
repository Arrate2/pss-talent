output "alb_dns_name" {
  description = "La DNS pública del Application Load Balancer"
  value       = aws_lb.application_lb.dns_name
}

output "rds_endpoint" {
  description = "El endpoint de la base de datos RDS PostgreSQL"
  value       = aws_db_instance.rds_postgres.address
}

