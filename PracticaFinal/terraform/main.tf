resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "PF-Claudia-VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "PF-Claudia-IGW"
  }
}

#subredes publicas
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "PF-Claudia-Public-Subnet-${count.index + 1}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

#subredes privadas
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.custom_vpc.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "PF-Claudia-Private-Subnet-${count.index + 1}"
    Tier = "Private"
  }
}

#tabla de enrutamiento publica
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PF-Claudia-Public-Route-Table"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

#NAT Gatevay
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "NAT-GW-GitOps-WP"
  }
  depends_on = [aws_internet_gateway.igw]
}

#tabla de enrutamiento privada
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "PF-Claudia-Private-Route-Table"
  }
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

#RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private.*.id

  tags = {
    Name = "PF-Claudia-RDS Subnet Group"
  }
}

#Grupos de seguridad ALB 
resource "aws_security_group" "sg_alb" {
  name        = "pf-claudia-alb-sg"
  description = "Allow HTTP and HTTPS inbound traffic from internet"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description = "HTTP Public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Public"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PF-Claudia-SG-ALB"
  }
}

#EC2 solo trafico desde el balanceador y SSH
resource "aws_security_group" "sg_web" {
  name        = "pf-web-sg"
  description = "Allow HTTP, HTTPS, SSH inbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PF-Claudia-SG-Webserver"
  }
}

resource "aws_security_group" "sg_rds" {
  name        = "pf-rds-sg"
  description = "Allow PostgreSQL acces from EC2 instances"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description     = "PostgreSQL from EC2 (ASG)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PF-Claudia-SG-RDS"
  }
}

#LB
resource "aws_lb" "application_lb" {
  name               = "wp-alb-gitops"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = aws_subnet.public_subnets.*.id

  tags = {
    Name = "PF-Claudia-Application-Load-Balancer"
  }
}

resource "aws_lb_target_group" "wp_tg" {
  name     = "wp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200-399"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}


#LAUNCH TEMPLATE
resource "aws_launch_template" "wp_launch_template" {
  name_prefix            = "wp-asg-lt"
  image_id               = data.aws_ami.ubuntu_latest.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.wordpress_keypair.key_name
  vpc_security_group_ids = [aws_security_group.sg_web.id]

  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "pf-claudia-web"
      Role = "web"
    }
  }
}

#autoscaling group
resource "aws_autoscaling_group" "wp_asg" {
  name                = "wp-asg"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.public_subnets.*.id
  target_group_arns   = [aws_lb_target_group.wp_tg.arn]

  launch_template {
    id      = aws_launch_template.wp_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "pf-claudia-web"
    propagate_at_launch = true
  }
  tag {
    key                 = "Role"
    value               = "web"
    propagate_at_launch = true
  }
}

resource "aws_db_instance" "rds_postgres" {
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  db_name           = var.db_name
  username          = var.db_user
  password          = var.db_pass

  multi_az            = false
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible    = false

  tags = {
    Name = "PF-Claudia-RDS-Postgres"
  }
}
