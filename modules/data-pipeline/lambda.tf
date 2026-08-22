data "archive_file" "a1_producer" {
  type        = "zip"
  source_dir  = "${path.module}/src/a1_producer"
  output_path = "${path.module}/build/a1_producer.zip"
}

resource "aws_lambda_function" "a1_producer" {
  function_name    = "A1Producer-secret"
  role             = aws_iam_role.a1_producer_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.a1_producer.output_path
  source_code_hash = data.archive_file.a1_producer.output_base64sha256

  environment {
    variables = {
      STREAM_NAME  = aws_kinesis_stream.security_stream.name
      OFFSET_TABLE = aws_dynamodb_table.auth_log_offset.name
      LOG_TABLE    = aws_dynamodb_table.security_logs.name
      LOG_BUCKET   = aws_s3_bucket.auth_log.id
      LOG_KEY      = "raw/auth.log"
      BATCH_SIZE   = "10"
    }
  }
}

data "archive_file" "a2_consumer" {
  type        = "zip"
  source_dir  = "${path.module}/src/a2_consumer"
  output_path = "${path.module}/build/a2_consumer.zip"
}

resource "aws_lambda_function" "a2_consumer" {
  function_name    = "A2Consumer-secret"
  role             = aws_iam_role.a2_consumer_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.a2_consumer.output_path
  source_code_hash = data.archive_file.a2_consumer.output_base64sha256

  environment {
    variables = {
      COUNTER_TABLE   = aws_dynamodb_table.security_risk_counters.name
      ANALYZED_BUCKET = aws_s3_bucket.auth_log.id
      ANALYZED_PREFIX = "analyzed"
      WINDOW_SECONDS  = "300"
      USE_COMPREHEND  = "true"
    }
  }
}

resource "aws_lambda_event_source_mapping" "a2_consumer_kinesis" {
  event_source_arn  = aws_kinesis_stream.security_stream.arn
  function_name     = aws_lambda_function.a2_consumer.arn
  starting_position = "LATEST"
  batch_size        = 10
}
