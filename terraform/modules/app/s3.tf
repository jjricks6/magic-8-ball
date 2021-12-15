resource "aws_s3_bucket" "magic_bucket" {
  bucket = "magic-bucket-${var.account_number}"
  acl    = "public-read"
  tags   = var.tags
  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::magic-bucket-${var.account_number}/*"
            }
        ]
    }
  EOF
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

module "template_files" {
  source = "hashicorp/dir/template"

  base_dir = "../../../dist"
}

resource "aws_s3_bucket_object" "magic_dist" {
  for_each = module.template_files.files

  bucket       = aws_s3_bucket.magic_bucket.bucket
  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  etag = each.value.digests.md5
}