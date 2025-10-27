variable "project_name" { type = string }
variable "vpc_primary_id" { type = string }
variable "vpc_secondary_id" { type = string }
variable "primary_private_subnet_ids" { type = list(string) }
variable "secondary_private_subnet_ids" { type = list(string) }

variable "db_engine" { type = string }
variable "db_engine_version" { type = string }
variable "db_instance_class" { type = string }
variable "db_name" { type = string }
variable "master_username" { type = string }
variable "master_password" { type = string }
variable "allocated_storage" { type = number }
variable "multi_az_primary" { type = bool }
