resource "aws_s3_bucket" "auth_log" {
  bucket = "auth-log-secret-namyoonah"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "auth_log" {
  bucket = aws_s3_bucket.auth_log.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}
