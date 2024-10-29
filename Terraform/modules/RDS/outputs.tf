output "rds_address" {
  value = aws_db_instance.postgres_db.address
}

output "rds_db" {
  value = aws_db_instance.postgres_db.id
}