output "nginx_public_ip" {
  description = "Public IP address of the NGINX web server"
  value       = aws_instance.web_server_ubuntu.public_ip
}
