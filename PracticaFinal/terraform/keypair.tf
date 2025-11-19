
# Guardar la llave pública en AWS como Key Pair usando la variable
resource "aws_key_pair" "wordpress_keypair" {
  key_name   = "parte3_wp_key"
  public_key = var.wordpress_public_key
}

