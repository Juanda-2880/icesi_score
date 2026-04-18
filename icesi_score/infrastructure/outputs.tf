output "rds_endpoint" {
  description = "Endpoint de conexión a la base de datos RDS PostgreSQL"
  value       = aws_db_instance.icesi_score.endpoint
}

output "rds_db_name" {
  description = "Nombre de la base de datos en RDS"
  value       = aws_db_instance.icesi_score.db_name
}
