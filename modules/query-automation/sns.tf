resource "aws_sns_topic" "security_approval" {
  name = "SecurityApprovalTopic_secretsong"
}

resource "aws_sns_topic_subscription" "approval_email" {
  topic_arn = aws_sns_topic.security_approval.arn
  protocol  = "email"
  endpoint  = var.approval_email
}
