data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "icesi_score" {
  name       = "icesi-score-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "lambda_sg" {
  name        = "icesi-score-lambda-sg"
  description = "Security group for IcesiScore Lambda functions"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "icesi-score-rds-sg"
  description = "Allow PostgreSQL access from Lambda SG and optionally from a dev IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  dynamic "ingress" {
    for_each = var.dev_my_ip != "" ? [var.dev_my_ip] : []
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["${ingress.value}/32"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "icesi_score" {
  identifier             = "icesi-score-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "icesi_score"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.icesi_score.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = var.dev_my_ip != ""
  skip_final_snapshot    = true
  deletion_protection    = false
  multi_az               = false
  backup_retention_period = 0
}
