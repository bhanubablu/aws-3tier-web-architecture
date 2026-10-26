# 1. ALB Security Group (Public facing)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allows inbound HTTP/HTTPS traffic to Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# 2. App Tier EC2 Security Group (Private tier)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Allows inbound traffic ONLY from Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP traffic exclusively from ALB Security Group"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Allow port 80 traffic exclusively from ALB Security Group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound to NAT Gateway for package updates and DB access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# 3. Database RDS Security Group (Isolated Private tier)
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allows inbound MySQL traffic ONLY from EC2 App Tier Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL port 3306 exclusively from App Tier Security Group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow no unrestricted egress from database"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
