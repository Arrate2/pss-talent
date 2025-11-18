

# Generar un par de llaves SSH localmente usando la variable
resource "tls_private_key" "wordpress_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Guardar la llave privada en un archivo local
resource "local_file" "private_key" {
  content              = tls_private_key.wordpress_key.private_key_pem
  filename             = "/home/vagrant/.ssh/parte3_wp_key.pem"
  file_permission      = "0600"
  directory_permission = "0755"
}

# Guardar la llave pública en AWS como Key Pair usando la variable
resource "aws_key_pair" "wordpress_keypair" {
  key_name   = "parte3_wp_key"
  public_key = tls_private_key.wordpress_key.public_key_openssh
}

