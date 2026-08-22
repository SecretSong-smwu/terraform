resource "aws_iam_role" "step_functions_role" {
  name = "StepFunctions-StateMachine-secretsong-role-frtruwke9"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "sns_publish_scoped" {
  name        = "SnsPublishScopedAccessPolicy-4492f1f4-bd45-4fc9-aa51-e55cee10aaea"
  path        = "/service-role/"
  description = "Allows AWS Step Functions to publish to SNS targets on your behalf."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = [aws_sns_topic.security_approval.arn]
      }
    ]
  })
}

resource "aws_iam_policy" "xray_access" {
  name        = "XRayAccessPolicy-1a65dd98-8860-4a29-bd92-233b9fa036cc"
  path        = "/service-role/"
  description = "Allow AWS Step Functions to call X-Ray daemon on your behalf"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_invoke_scoped" {
  name        = "LambdaInvokeScopedAccessPolicy-5b4ebdac-ed42-4f49-8f08-efed412459c4"
  path        = "/service-role/"
  description = "Allow AWS Step Functions to invoke Lambda functions on your behalf"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          "${aws_lambda_function.get_risk_analysis.arn}:*",
          "${aws_lambda_function.refresh_data.arn}:*",
          "${aws_lambda_function.block_ip.arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          aws_lambda_function.get_risk_analysis.arn,
          aws_lambda_function.refresh_data.arn,
          aws_lambda_function.block_ip.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_lambda_execute" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "sfn_sns_publish" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.sns_publish_scoped.arn
}

resource "aws_iam_role_policy_attachment" "sfn_xray" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.xray_access.arn
}

resource "aws_iam_role_policy_attachment" "sfn_lambda_invoke" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.lambda_invoke_scoped.arn
}

resource "aws_sfn_state_machine" "secretsong" {
  name     = "StateMachine-secretsong"
  role_arn = aws_iam_role.step_functions_role.arn
  type     = "STANDARD"

  definition = templatefile("${path.module}/templates/state_machine.asl.json", {
    refresh_data_arn     = aws_lambda_function.refresh_data.arn
    get_risk_analysis_arn = aws_lambda_function.get_risk_analysis.arn
    block_ip_arn          = aws_lambda_function.block_ip.arn
    sns_topic_arn          = aws_sns_topic.security_approval.arn
    approve_url             = "https://${aws_api_gateway_rest_api.security_soar_approval.id}.execute-api.ap-northeast-2.amazonaws.com/prod/approve"
    reject_url              = "https://${aws_api_gateway_rest_api.security_soar_approval.id}.execute-api.ap-northeast-2.amazonaws.com/prod/reject"
  })
}
