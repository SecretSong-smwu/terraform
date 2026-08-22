resource "aws_wafv2_ip_set" "soar_blocked_ips" {
  name               = "SOARBlockedIPs-secretsong"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  # BlockIP Lambda가 런타임에 addresses를 동적으로 갱신하므로,
  # Terraform이 초기 import 시점 값으로 되돌리지 않도록 무시함
  addresses = [
    "218.25.17.234/32",
    "173.192.158.3/32"
  ]

  lifecycle {
    ignore_changes = [addresses]
  }
}

resource "aws_wafv2_web_acl" "secretsong" {
  name        = "webACL_secretsong"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "BlockRule-secretsong"
    priority = 0

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.soar_blocked_ips.arn
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockRule-secretsong"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "webACL_secretsong"
  }
}

resource "aws_wafv2_web_acl_association" "api_gateway_stage" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.secretsong.arn
}
