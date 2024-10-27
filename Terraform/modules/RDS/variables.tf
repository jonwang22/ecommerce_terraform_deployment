variable wl5vpc_id {}

variable db_instance_class {
  description = "The instance type of the RDS instance"
  default     = "db.t3.micro"
}

variable private_subnet_1_id {}

variable private_subnet_2_id {}

variable backend_sg {}

variable db_name {
  description = "The name of the database to create when the DB instance is created"
  type        = string
}

variable db_username {
  description = "Username for the master DB user"
  type        = string
}

variable db_password {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}