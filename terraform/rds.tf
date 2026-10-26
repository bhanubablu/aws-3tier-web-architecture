# RDS Subnet Group across Multi-AZ
resource "aws_db_subnet_group" "rds" {
  name        = "${var.project_name}-rds-subnet-group"
  description = "Subnet group for Multi-AZ private RDS deployment"
  subnet_ids  = aws_subnet.db[*].id

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# RDS MySQL Instance (Multi-AZ Enabled)
resource "aws_db_instance" "rds" {
  identifier        = "${var.project_name}-mysql-db"
  allocated_storage = 20
  storage_type      = "gp3"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = true
  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  tags = {
    Name = "${var.project_name}-rds-mysql"
    Tier = "Private-Database"
  }
}
