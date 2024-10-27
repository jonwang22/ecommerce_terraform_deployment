variable instance_type {
    description     = "Default EC2 Instance to use."
    type            = string
    default         = "t3.micro"
} 

variable wl5vpc_id {
    description     = "VPC ID from VPC Module"
}

variable public_subnet_1_id {}

variable public_subnet_2_id {}

variable private_subnet_1_id {}

variable private_subnet_2_id {}

variable ami {
    default         = "ami-0866a3c8686eaeeba"
}