output "backend_sg" {
    value = aws_security_group.backend_sg.id
}

output "wl5frontend1" {
    value = aws_instance.wl5frontend1.id
}

output "wl5frontend2" {
    value = aws_instance.wl5frontend2.id
}