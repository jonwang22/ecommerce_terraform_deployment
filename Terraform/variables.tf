# AWS General Variables
variable access_key{
  type=string
  sensitive=true
}
variable secret_key{
  type=string
  sensitive=true
}
variable region{}

# RDS Database Variables
variable db_name {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "ecommercedb"
}

variable db_username {
  description = "Username for the master DB user"
  type        = string
  default     = "kurac5user"
}

variable db_password {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}