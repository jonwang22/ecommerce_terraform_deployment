# AWS General Variables
variable aws_access_key{
  type=string
  sensitive=true
}
variable aws_secret_key{
  type=string
  sensitive=true
}
variable region{
  default = "us-east-1"
}

# EC2 General Variables
# variable "public_key_path" {
#   description = "Path to the public key file"
#   type        = string
#   default     = "/home/ubuntu/.ssh/ecommerce.pub"  # You can also pass this as an environment variable
# }

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