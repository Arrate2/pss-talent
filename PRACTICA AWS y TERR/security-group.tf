# Define el Security Group
resource "aws_security_group" "web_traffic_sg" {
  vpc_id = aws_vpc.demo_vpc.id

  name        = "sgwebpublico"
  description = "Permite trafico entrante HTTP (80) y HTTPS (443)"
  tags = {
    Name = "Web-Security-Group"
  }
}

# Regla de INGRESS (Entrada) para el puerto 80 y 443
resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Permite el trafico desde cualquier IP
  security_group_id = aws_security_group.web_traffic_sg.id
}

resource "aws_security_group_rule" "ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Permite el trafico desde cualquier IP
  security_group_id = aws_security_group.web_traffic_sg.id
}

