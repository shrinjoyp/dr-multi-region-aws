output "primary_website_bucket" {
  value = module.s3_crr.primary_bucket_name
}
output "secondary_website_bucket" {
  value = module.s3_crr.secondary_bucket_name
}
output "app_dns_name" {
  value = "app.${var.domain_name}"
}
output "primary_db_endpoint" {
  value = module.rds.primary_endpoint
}
output "read_replica_endpoint" {
  value = module.rds.secondary_rr_endpoint
}
