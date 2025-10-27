data "aws_kms_alias" "rds_secondary" {
  provider = aws.secondary
  name     = "alias/aws/rds"
}

# Security groups allowing local VPC access (tighten as needed)
resource "aws_security_group" "rds_primary" {
  name        = "${var.project_name}-rds-primary"
  description = "RDS primary SG"
  vpc_id      = var.vpc_primary_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "primary" {
  name       = "${var.project_name}-primary"
  subnet_ids = var.primary_private_subnet_ids
}

resource "aws_db_instance" "primary" {
  identifier              = "${var.project_name}-primary"
  allocated_storage       = var.allocated_storage
  engine                  = var.db_engine
  instance_class          = var.db_instance_class
  db_name                 = var.db_name
  username                = var.master_username
  password                = var.master_password
  multi_az                = var.multi_az_primary
  storage_encrypted       = true
  backup_retention_period = 7
  vpc_security_group_ids  = [aws_security_group.rds_primary.id]
  db_subnet_group_name    = aws_db_subnet_group.primary.name
  skip_final_snapshot     = true
}

# Read replica in secondary region
resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${var.project_name}-secondary"
  subnet_ids = var.secondary_private_subnet_ids
}

resource "aws_security_group" "rds_secondary" {
  provider    = aws.secondary
  name        = "${var.project_name}-rds-secondary"
  description = "RDS secondary SG"
  vpc_id      = var.vpc_secondary_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "read_replica" {
  provider               = aws.secondary
  identifier             = "${var.project_name}-rr"
  replicate_source_db    = aws_db_instance.primary.arn
  instance_class         = var.db_instance_class
  storage_encrypted      = true
  kms_key_id             = data.aws_kms_alias.rds_secondary.arn
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_secondary.id]
  db_subnet_group_name   = aws_db_subnet_group.secondary.name
  depends_on             = [aws_db_instance.primary]
}

output "primary_endpoint" { value = aws_db_instance.primary.address }
output "secondary_rr_endpoint" { value = aws_db_instance.read_replica.address }
