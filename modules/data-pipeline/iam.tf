resource "aws_iam_role" "a1_producer_role" {
  name = "A1Producer-secret-role-bp1866ab"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "a1_producer_inline" {
  name = "A1Producer-secret-inline-policy"
  role = aws_iam_role.a1_producer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "KinesisPutAccess"
        Effect   = "Allow"
        Action   = "kinesis:PutRecord"
        Resource = aws_kinesis_stream.security_stream.arn
      },
      {
        Sid    = "DynamoDBOffsetAccess"
        Effect = "Allow"
        Action = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource = aws_dynamodb_table.auth_log_offset.arn
      },
      {
        Sid      = "DynamoDBLogStorageAccess"
        Effect   = "Allow"
        Action   = "dynamodb:PutItem"
        Resource = aws_dynamodb_table.security_logs.arn
      },
      {
        Sid      = "S3ReadAuthLog"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.auth_log.arn}/raw/auth.log"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "a1_producer_basic_execution" {
  role       = aws_iam_role.a1_producer_role.name
  policy_arn = "arn:aws:iam::054422645032:policy/service-role/AWSLambdaBasicExecutionRole-0ff532a2-2a10-4169-950b-2791baf20ddd"
}

resource "aws_iam_role" "a2_consumer_role" {
  name = "A2Consumer-secret-role-n5826b0c"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "a2_consumer_inline" {
  name = "A2Consumer-secret-inline-policy"
  role = aws_iam_role.a2_consumer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KinesisConsumeAccess"
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:ListShards",
          "kinesis:ListStreams"
        ]
        Resource = aws_kinesis_stream.security_stream.arn
      },
      {
        Sid    = "CounterTableAccess"
        Effect = "Allow"
        Action = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource = aws_dynamodb_table.security_risk_counters.arn
      },
      {
        Sid      = "S3WriteAnalyzed"
        Effect   = "Allow"
        Action    = "s3:PutObject"
        Resource = "${aws_s3_bucket.auth_log.arn}/analyzed/*"
      },
      {
        Sid      = "ComprehendAccess"
        Effect   = "Allow"
        Action   = "comprehend:DetectKeyPhrases"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "a2_consumer_basic_execution" {
  role       = aws_iam_role.a2_consumer_role.name
  policy_arn = "arn:aws:iam::054422645032:policy/service-role/AWSLambdaBasicExecutionRole-1e599380-a47c-4e2d-a67c-2707f17ce783"
}
