resource "aws_route53_record" "magic_r53_record" {
  name    = aws_api_gateway_domain_name.magic_api_domain.domain_name
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.magic_api_domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.magic_api_domain.regional_zone_id
  }
}

resource "aws_route53_record" "magic_cloudfront_a_record" {
  name    = var.domain_name
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.magic_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.magic_distribution.hosted_zone_id
  }
}

resource "aws_route53_record" "magic_cloudfront_cname_record" {
  zone_id = var.hosted_zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  records = [var.domain_name]
}