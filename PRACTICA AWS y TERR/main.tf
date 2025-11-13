resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Claudia VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.demo_vpc.id
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo_vpc.id
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rtb.id
}
# Data Source para buscar la AMI de Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] 
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
#claves ssh
resource "aws_key_pair" "key_for_ec2" {
  key_name   = "mi-clave-claudia" # Nombre que tendrá la clave en AWS
  public_key = file("C:\\Users\\carrate\\.ssh\\id_rsa.pub") 
}
# Recurso de la Instancia EC2
resource "aws_instance" "web_server_ubuntu" {
  ami           = data.aws_ami.ubuntu.id      
  instance_type = "t3.micro"                  
  associate_public_ip_address = true
  key_name      = aws_key_pair.key_for_ec2.key_name 
  subnet_id     = aws_subnet.public_subnet.id
  
  # Asocia el Security Group creado previamente
  vpc_security_group_ids = [aws_security_group.web_traffic_sg.id] 

  tags = {
    Name = "Web-Server-Ubuntu"
  }
}