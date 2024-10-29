output "rds_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}

output "rds_db" {
  value = aws_db_instance.postgres_db.id
}