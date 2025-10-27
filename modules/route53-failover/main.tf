# Health check for primary endpoint
resource "aws_route53_health_check" "primary" {
  fqdn              = var.health_check_fqdn
  port              = var.health_check_port
  type              = "HTTP"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  tags              = { Name = "primary-healthcheck" }
}

# PRIMARY CNAME
resource "aws_route53_record" "primary" {
  zone_id = var.hosted_zone_id
  name    = var.record_name
  type    = "CNAME"
  ttl     = 30
  records = [var.primary_value]

  set_identifier = "primary"
  failover_routing_policy { type = "PRIMARY" }
  health_check_id = aws_route53_health_check.primary.id
}

# SECONDARY CNAME
resource "aws_route53_record" "secondary" {
  zone_id = var.hosted_zone_id
  name    = var.record_name
  type    = "CNAME"
  ttl     = 30
  records = [var.secondary_value]

  set_identifier = "secondary"
  failover_routing_policy { type = "SECONDARY" }
}
