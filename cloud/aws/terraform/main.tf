resource "aws_ecr_repository" "app" {
  name = local.name
  image_scanning_configuration { scan_on_push = true }
  tags = local.tags
}

resource "aws_s3_bucket" "artifact" {
  bucket        = local.name
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "artifact" {
  bucket = aws_s3_bucket.artifact.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.id
  rule {
    id     = "expire-older"
    status = "Enabled"
    # Filtre requis : prefix="" = tout le bucket
    filter { prefix = "" }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

output "ecr_repository_url" { value = aws_ecr_repository.app.repository_url }
output "s3_bucket_name"    { value = aws_s3_bucket.artifact.bucket }
