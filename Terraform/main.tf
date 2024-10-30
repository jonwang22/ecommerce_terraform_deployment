# Configure the AWS provider block. This tells Terraform which cloud provider to use and 
# how to authenticate (access key, secret key, and region) when provisioning resources.
# Note: Hardcoding credentials is not recommended for production use.
# Instead, use environment variables or IAM roles to manage credentials securely.
# Indicating Provider for Terraform to use
provider "aws" {
  access_key = var.aws_access_key        # Replace with your AWS access key ID (leave empty if using IAM roles or env vars)
  secret_key = var.aws_secret_key        # Replace with your AWS secret access key (leave empty if using IAM roles or env vars)
  region     = var.region           # Specify the AWS region where resources will be created (e.g., us-east-1, us-west-2)
}

module "VPC" {
  source = "./modules/VPC"
}

module "ALB" {
  source = "./modules/ALB"
  wl5vpc_id = module.VPC.wl5vpc_id
  public_subnet_1_id = module.VPC.public_subnet_1_id
  public_subnet_2_id = module.VPC.public_subnet_2_id
  wl5frontend1 = module.EC2.wl5frontend1
  wl5frontend2 = module.EC2.wl5frontend2
}

module "EC2" {
  source = "./modules/EC2"
  wl5vpc_id = module.VPC.wl5vpc_id
  public_subnet_1_id = module.VPC.public_subnet_1_id
  public_subnet_2_id = module.VPC.public_subnet_2_id
  private_subnet_1_id = module.VPC.private_subnet_1_id
  private_subnet_2_id = module.VPC.private_subnet_2_id
  # public_key_path = var.public_key_path
  rds_address = module.RDS.rds_address
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  rds_db = module.RDS.rds_db
}

module "RDS" {
  source = "./modules/RDS/"
  wl5vpc_id = module.VPC.wl5vpc_id
  backend_sg = module.EC2.backend_sg
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  private_subnet_1_id = module.VPC.private_subnet_1_id
  private_subnet_2_id = module.VPC.private_subnet_2_id
}