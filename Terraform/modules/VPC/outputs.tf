# Output block to display the public IP address of the created EC2 instance.
# Outputs are displayed at the end of the 'terraform apply' command and can be accessed using `terraform output`.
# They are useful for sharing information about your infrastructure that you may need later (e.g., IP addresses, DNS names).
output "wl5vpc_id" {
  value = aws_vpc.wl5vpc.id  # Display the VPC ID.
}
output "default_vpc_id" {
  value = data.aws_vpc.default.id
}
output "public_subnet_1_id" {
  value = aws_subnet.public_subnet_1.id  # Display public subnet ID.
}
output "public_subnet_2_id" {
  value = aws_subnet.public_subnet_2.id  # Display public subnet ID.
}
output "private_subnet_1_id" {
  value = aws_subnet.private_subnet_1.id  # Display public subnet ID.
}
output "private_subnet_2_id" {
  value = aws_subnet.private_subnet_2.id  # Display public subnet ID.
}