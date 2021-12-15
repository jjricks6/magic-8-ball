data "aws_route53_zone" "magic_zone" {
  zone_id      = var.hosted_zone_id
  private_zone = false
}

resource "aws_acm_certificate" "magic_cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  provider                  = aws.us-east-1
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
  provider                = aws.us-east-1
  timeouts {
    create = "5m"
  }
}

### Oregon

resource "aws_acm_certificate" "magic_cert_oregon" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  provider                  = aws.us-west-2
  tags = {
    IAC = "Terraform"
  }
}

resource "aws_route53_record" "magic_cert_validation_oregon" {
  for_each = {
    for dvo in aws_acm_certificate.magic_cert_oregon.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "magic_cert_oregon" {
  certificate_arn         = aws_acm_certificate.magic_cert_oregon.arn
  validation_record_fqdns = [for record in aws_route53_record.magic_cert_validation_oregon : record.fqdn]
  provider                = aws.us-west-2
  timeouts {
    create = "5m"
  }
}
