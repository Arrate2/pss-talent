data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (dueños de Ubuntu)

  filter {
    name   = "name"
    # Busca la imagen de Ubuntu 20.04 LTS (HVM)
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
 }
}
# 1. Crear una VPC personalizada 
resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Parte3-VPC"
  }
}

# 2. Crear un Internet Gateway (IGW) para la salida a internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "Parte3-IGW"
  }
}

# 3. Crear 2 Subredes Públicas en diferentes AZs 
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Para asignar IP pública automáticamente

  tags = {
    Name = "Parte-3-Public-Subnet-${count.index + 1}"
  }
}

# Data Source para obtener las AZs disponibles
data "aws_availability_zones" "available" {
  state = "available"
}

# 4. Crear la Tabla de Ruteo para el tráfico de internet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Parte3-Public-Route-Table"
  }
}

# 5. Asociar la Tabla de Ruteo a las subredes públicas
resource "aws_route_table_association" "public_rta" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Security Group para el Webserver 
resource "aws_security_group" "sg_web" {
  name        = "parte3-web-sg"
  description = "Allow HTTP, HTTPS, SSH inbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  # Regla de entrada para HTTP/80 desde cualquier lugar 
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de entrada para HTTPS/443 desde cualquier lugar 
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de entrada para SSH/22 desde cualquier lugar (Prueba) 
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Tráfico de salida hacia cualquier lugar
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Parte3-SG-Webserver"
  }
}

# 7. Security Group para el Database Server 
resource "aws_security_group" "sg_db" {
  name        = "Parte3-db-sg"
  description = "Allow MariaDB/MySQL traffic only from Webserver SG"
  vpc_id      = aws_vpc.custom_vpc.id

  # Regla de entrada para la DB (e.g., 3306) SOLO desde el SG del Webserver 
  ingress {
    description     = "MySQL/MariaDB from Webserver"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id] # Referencia cruzada
  }

  # Regla de entrada para SSH/22 desde cualquier lugar (Administración) 
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  # Tráfico de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Parte3-SG-Database"
  }
}

# -------------------- RECURSOS DE CÓMPUTO (INSTANCIAS EC2) --------------------

# 1. Instancia del Webserver
resource "aws_instance" "webserver" {
  ami                         = data.aws_ami.ubuntu_latest.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public_subnets[0].id # Subred 1
  vpc_security_group_ids      = [aws_security_group.sg_web.id]
  associate_public_ip_address = true

  tags = {
    Name = "WordPress-Webserver"
    role = "web" # <-- Etiqueta requerida para Ansible
  }
}

# 2. Instancia del Database Server
resource "aws_instance" "dbserver" {
  ami                         = data.aws_ami.ubuntu_latest.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public_subnets[1].id # Subred 2
  vpc_security_group_ids      = [aws_security_group.sg_db.id]
  associate_public_ip_address = true # Para simplificar el acceso de Ansible y la prueba

  tags = {
    Name = "WordPress-Database"
    role = "db" # <-- Etiqueta requerida para Ansible
  }
}
