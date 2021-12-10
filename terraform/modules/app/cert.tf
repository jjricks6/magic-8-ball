data "aws_route53_zone" "magic_zone" {
  zone_id      = "Z09767571D0IVLLXRR8P3"
  private_zone = false
}

resource "aws_acm_certificate" "magic_cert" {
  domain_name               = "8-ball.ml"
  subject_alternative_names = ["*.8-ball.ml"]
  validation_method         = "DNS"
  tags = {
    IAC = "Terraform"
  }
}

resource "aws_route53_record" "magic_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.magic_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.magic_zone.id
}

resource "aws_acm_certificate_validation" "magic_cert" {
  certificate_arn         = aws_acm_certificate.magic_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.magic_cert_validation : record.fqdn]
  timeouts {
    create = "5m"
  }
}
