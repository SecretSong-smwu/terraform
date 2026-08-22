resource "aws_dynamodb_table" "security_logs" {
  name         = "SecurityLogs-secret"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "log_id"

  attribute {
    name = "log_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "security_risk_counters" {
  name         = "SecurityRiskCounters-secret"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "src_ip"

  attribute {
    name = "src_ip"
    type = "S"
  }
}

resource "aws_dynamodb_table" "auth_log_offset" {
  name         = "auth-log-offset-secret"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }
}
