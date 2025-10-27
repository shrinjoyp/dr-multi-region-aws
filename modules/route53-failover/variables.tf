variable "hosted_zone_id" { type = string }
variable "record_name" { type = string }
variable "primary_value" { type = string }
variable "secondary_value" { type = string }

variable "health_check_fqdn" { type = string }
variable "health_check_path" { type = string }
variable "health_check_port" { type = number }
