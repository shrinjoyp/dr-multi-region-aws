variable "project_name" { type = string }
variable "primary_region" { type = string }
variable "secondary_region" { type = string }

variable "vpc_primary_cidr" { type = string }
variable "vpc_secondary_cidr" { type = string }

variable "domain_name" { type = string }
variable "hosted_zone_id" { type = string }

variable "db_engine" { type = string }
variable "db_engine_version" { type = string }
variable "db_instance_class" { type = string }
variable "db_name" { type = string }
variable "master_username" { type = string }
variable "master_password" { type = string }
variable "allocated_storage" { type = number }
variable "multi_az_primary" { type = bool }

variable "create_route53" {
  type    = bool
  default = false
}
