resource "aws_kinesis_stream" "security_stream" {
  name             = "security-stream-secret"
  retention_period = 24

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}
