##################################################
### SSH KEY ###
##################################################
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "ecommerce"
  public_key = file("~/.ssh/ecommerce.pub")  # Path to your public key file
}

##################################################
### FRONTEND ###
##################################################
# Create an EC2 instance in AWS. This resource block defines the configuration of the instance.
# This EC2 is created in our Public Subnet
# Frontend AZ1
resource "aws_instance" "wl5frontend1" {
  ami               = var.ami                          # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
  instance_type     = var.instance_type                # Specify the desired EC2 instance size.
  subnet_id         = var.public_subnet_1_id
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name          = "ecommerce"                # The key pair name for SSH access to the instance.
  #user_data         = "${file("install_jenkins.sh")}"
  
  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_frontend_az1"
  }
}

# Frontend AZ2
resource "aws_instance" "wl5frontend2" {
  ami               = var.ami                          # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
  instance_type     = var.instance_type                # Specify the desired EC2 instance size.
  subnet_id         = var.public_subnet_2_id
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name          = "ecommerce"                # The key pair name for SSH access to the instance.
  #user_data         = "${file("install_jenkins.sh")}"
  
  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_frontend_az2"
  }
}

# Create a security group named "tf_made_sg" that allows SSH and HTTP traffic.
# This security group will be associated with the EC2 instance created above.
# This is Security Group for Jenkins
resource "aws_security_group" "frontend_sg" { # aws_security_group is the actual AWS resource name. web_ssh is the name stored by Terraform locally for record keeping 
  vpc_id      = var.wl5vpc_id
  name        = "WL5 FrontendSG"
  description = "Security group for Frontend EC2 instances."
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0                                     # Allow all outbound traffic (from port 0 to any port)
    to_port     = 0
    protocol    = "-1"                                  # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]                         # Allow traffic to any IP address
  }
  # Tags for the security group
  tags = {
    "Name"      : "WL5 FrontendSG"                          # Name tag for the security group
    "Terraform" : "true"                                # Custom tag to indicate this SG was created with Terraform
  }
}

##################################################
### BACKEND ###
##################################################
# Create an EC2 instance in AWS. This resource block defines the configuration of the instance.
# This EC2 is created in our Public Subnet
# Backend AZ1
resource "aws_instance" "wl5backend1" {
  ami               = var.ami                          # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
  instance_type     = var.instance_type                # Specify the desired EC2 instance size.
  subnet_id         = var.private_subnet_1_id
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.backend_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name          = "ecommerce"                # The key pair name for SSH access to the instance.
  #user_data         = "${file("install_jenkins.sh")}"
  
  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_backend_az1"
  }
}

# Backend AZ2
resource "aws_instance" "wl5backend2" {
  ami               = var.ami                          # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
  instance_type     = var.instance_type                # Specify the desired EC2 instance size.
  subnet_id         = var.private_subnet_2_id
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.backend_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name          = "ecommerce"                # The key pair name for SSH access to the instance.
  #user_data         = "${file("install_jenkins.sh")}"
  
  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_backend_az2"
  }
}

# Create a security group named "tf_made_sg" that allows SSH and HTTP traffic.
# This security group will be associated with the EC2 instance created above.
# This is Security Group for Jenkins
resource "aws_security_group" "backend_sg" { # aws_security_group is the actual AWS resource name. web_ssh is the name stored by Terraform locally for record keeping 
  vpc_id      = var.wl5vpc_id
  name        = "WL5 BackendSG"
  description = "Security group for Backend EC2 instances"
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/20"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0                                     # Allow all outbound traffic (from port 0 to any port)
    to_port     = 0
    protocol    = "-1"                                  # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]                         # Allow traffic to any IP address
  }
  # Tags for the security group
  tags = {
    "Name"      : "WL5 BackendSG"                          # Name tag for the security group
    "Terraform" : "true"                                # Custom tag to indicate this SG was created with Terraform
  }
}