data "archive_file" "get_security_logs" {
  type        = "zip"
  source_dir  = "${path.module}/src/get_security_logs"
  output_path = "${path.module}/build/get_security_logs.zip"
}

resource "aws_lambda_function" "get_security_logs" {
  function_name    = "GetSecurityLogs-secretsong"
  role             = aws_iam_role.agent_query_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 128
  filename         = data.archive_file.get_security_logs.output_path
  source_code_hash = data.archive_file.get_security_logs.output_base64sha256

  environment {
    variables = {
      LOG_TABLE = "SecurityLogs-secret"
    }
  }
}
