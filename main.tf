# Random suffix to keep bucket names globally unique
resource "random_id" "suffix" {
  byte_length = 3
}

module "vpc_primary" {
  source     = "./modules/vpc"
  providers  = { aws = aws.primary }
  name       = "${var.project_name}-primary"
  cidr_block = var.vpc_primary_cidr
  az_count   = 2
}

module "vpc_secondary" {
  source     = "./modules/vpc"
  providers  = { aws = aws.secondary }
  name       = "${var.project_name}-secondary"
  cidr_block = var.vpc_secondary_cidr
  az_count   = 2
}

module "s3_crr" {
  source              = "./modules/s3-crr"
  providers           = { aws = aws.primary, aws.secondary = aws.secondary }
  project_name        = var.project_name
  unique_suffix       = random_id.suffix.hex
  replication_enabled = true
}

module "rds" {
  source                       = "./modules/rds-cross-region"
  providers                    = { aws = aws.primary, aws.secondary = aws.secondary }
  project_name                 = var.project_name
  vpc_primary_id               = module.vpc_primary.vpc_id
  vpc_secondary_id             = module.vpc_secondary.vpc_id
  primary_private_subnet_ids   = module.vpc_primary.private_subnet_ids
  secondary_private_subnet_ids = module.vpc_secondary.private_subnet_ids
  db_engine                    = var.db_engine
  db_engine_version            = var.db_engine_version
  db_instance_class            = var.db_instance_class
  db_name                      = var.db_name
  master_username              = var.master_username
  master_password              = var.master_password
  allocated_storage            = var.allocated_storage
  multi_az_primary             = var.multi_az_primary
}

module "route53" {
  count          = var.create_route53 ? 1 : 0
  source         = "./modules/route53-failover"
  providers      = { aws = aws.primary }
  hosted_zone_id = var.hosted_zone_id
  record_name    = "app.${var.domain_name}"

  # Two S3 static website endpoints (primary/secondary) as simple demo targets
  primary_value   = module.s3_crr.primary_website_endpoint
  secondary_value = module.s3_crr.secondary_website_endpoint

  health_check_fqdn = module.s3_crr.primary_website_endpoint
  health_check_path = "/"
  health_check_port = 80
}
