data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
 }
}

# 1. Crear una VPC personalizada
resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "PF-VPC"
  }
}

# 2. Crear un Internet Gateway (IGW) para la salida a internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "PF-IGW"
  }
}

# 3. Crear 2 Subredes Públicas en diferentes AZs
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "PF-Public-Subnet-${count.index + 1}"
  }
}


# Data Source para obtener las AZs disponibles
data "aws_availability_zones" "available" {
  state = "available"
}

# Creamos las subredes privadas
# --- Subredes Privadas (Para RDS PostgreSQL) ---
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.custom_vpc.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name    = "Private-Subnet-${count.index + 1}"
    Tier    = "Private"
  }
}

# Subnet Group para RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private.*.id
  tags = {
    Name = "RDS Subnet Group"
  }
}

# Elastic IP (EIP) para el NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# 4b. NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id
  tags = {
    Name = "NAT-GW-GitOps-WP"
  }
  depends_on = [aws_internet_gateway.igw]
}

# --- 1. Tabla de Ruteo Pública ---

# 1a. Crear la Tabla de Ruteo para el tráfico de internet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  # Ruta de salida a Internet a través del IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PF-Public-Route-Table"
  }
}

# 1b. Asociación: Enlaza la Tabla Pública a TODAS las Subredes Públicas
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


# --- 2. Tabla de Ruteo Privada ---

# 2a. Tabla de Rutas Privadas
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.custom_vpc.id
  tags = {
    Name = "Private-Route-Table"
  }
}

# 2b. Regla de salida a Internet para Subredes Privadas (Vía NAT Gateway)
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# 2c. Asociación: Enlaza la Tabla Privada a TODAS las Subredes Privadas
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group para el Application Load Balancer (ALB)
resource "aws_security_group" "sg_alb" {
  name        = "pf-alb-sg"
  description = "Allow HTTP and HTTPS inbound traffic from internet"
  vpc_id      = aws_vpc.custom_vpc.id

  # Regla de entrada para HTTP/80 desde cualquier lugar (0.0.0.0/0)
  ingress {
    description = "HTTP Public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de entrada para HTTPS/443 desde cualquier lugar (0.0.0.0/0)
  ingress {
    description = "HTTPS Public"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tráfico de salida (Egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PF-SG-ALB"
  }
}

# Security Group para el Webserver (ASG Instances)
resource "aws_security_group" "sg_web" {
  name        = "pf-web-sg"
  description = "Allow HTTP, HTTPS, SSH inbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  # Regla de entrada para HTTP/80: SOLO desde el SG del ALB
  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  # Regla de entrada para HTTPS/443: SOLO desde el SG del ALB
  ingress {
    description = "HTTPS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  # Regla de entrada para SSH/22 desde cualquier lugar (Prueba)
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tráfico de salida hacia cualquier lugar
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PF-SG-Webserver"
  }
}

# 7. Security Group para RDS
resource "aws_security_group" "sg_rds" {
  name        = "pf-rds-sg"
  description = "Allow PostgreSQL acces from EC2 instances"
  vpc_id      = aws_vpc.custom_vpc.id

  # Regla de entrada para PostgreSQL (5432)
  ingress {
    description     = "PostgreSQL from EC2 (ASG)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  # Tráfico de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PF-SG-RDS"
  }
}

# -------------------- RECURSOS DE ALTA DISPONIBILIDAD --------------------

# --- Application Load Balancer (ALB) ---
resource "aws_lb" "application_lb" {
  name               = "wp-alb-gitops"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = aws_subnet.public_subnets.*.id
  
  tags = {
    Name = "WP-Application-Load-Balancer"
  }
}

# Target Group (Grupo de Destino)
resource "aws_lb_target_group" "wp_tg" {
  name     = "wp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200-399"
  }
}

# Listener (Oyente de Tráfico en puerto 80)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}


# --- Base de Datos RDS PostgreSQL ---
resource "aws_db_instance" "rds_postgres" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15.2" 
  instance_class       = "db.t3.small"
  db_name              = var.db_name 
  username             = var.db_user
  password             = var.db_pass
  
  multi_az             = true 
  skip_final_snapshot  = true
  
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible    = false
  
  tags = {
    Name = "WP-RDS-Postgres"
  }
}


# --- Auto Scaling Group (ASG) ---

# Launch Template (Plantilla de Lanzamiento para las EC2)
resource "aws_launch_template" "wp_launch_template" {
  name_prefix   = "wp-asg-lt"
  image_id      = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.wordpress_keypair.key_name

  vpc_security_group_ids = [aws_security_group.sg_web.id]

  # USER DATA: Script para instalar Python (necesario para Ansible)
  user_data = base64encode(<<EOF
  tags = {
    Name = "WP-ASG-Instance"
    role = "web"
  }
}

# Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "wp_asg" {
  name = "wp-asg"
  
  min_size             = 2 
  max_size             = 4
  desired_capacity     = 2

  vpc_zone_identifier  = aws_subnet.public_subnets.*.id

  # Vinculación con el Load Balancer
  target_group_arns    = [aws_lb_target_group.wp_tg.arn]

  launch_template {
    id      = aws_launch_template.wp_launch_template.id
    version = "$$Latest"
  }

  tags = [{
    key                 = "Name"
    value               = "WP-ASG-Instance"
    propagate_at_launch = true
  }]
}

# --- SALIDAS (OUTPUTS) ---
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.application_lb.dns_name
}
output "rds_endpoint" {
  description = "The RDS PostgreSQL endpoint for Ansible configuration"
  value       = aws_db_instance.rds_postgres.address
}
