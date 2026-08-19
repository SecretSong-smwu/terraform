resource "aws_iam_role" "agent_query_lambda_role" {
  name = "AgentQueryLambdaRole-secretsong"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "readaccess" {
  name = "AgentQueryLambdaRole-secretsong-readaccess"
  role = aws_iam_role.agent_query_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSecurityLogs"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:ap-northeast-2:054422645032:table/SecurityLogs-secret"
      },
      {
        Sid    = "ReadAnalyzedResults"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::auth-log-secret-namyoonah",
          "arn:aws:s3:::auth-log-secret-namyoonah/analyzed/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "agent_query_policy" {
  name = "AgentQueryLambdaRole-secretsongPolicy"

  # NACL 관련 권한(ec2:CreateNetworkAclEntry, ec2:DescribeNetworkAcls)은
  # 초기 NACL 기반 차단 설계에서 쓰였으나 WAF 방식으로 전환하며 미사용 상태가 되어 제거함(v10)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:ap-northeast-2:054422645032:table/SecurityLogs-secret"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::auth-log-secret-namyoonah",
          "arn:aws:s3:::auth-log-secret-namyoonah/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = "arn:aws:lambda:ap-northeast-2:054422645032:function:A1Producer-secret"
      },
      {
        Effect = "Allow"
        Action = [
          "states:SendTaskSuccess",
          "states:SendTaskFailure"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "wafv2:GetIPSet",
          "wafv2:UpdateIPSet"
        ]
        Resource = "arn:aws:wafv2:ap-northeast-2:054422645032:regional/ipset/SOARBlockedIPs-secretsong/af108f19-75cf-4e96-b125-6444d78f3002"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_policy" {
  role       = aws_iam_role.agent_query_lambda_role.name
  policy_arn = aws_iam_policy.agent_query_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_execute" {
  role       = aws_iam_role.agent_query_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.agent_query_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role       = aws_iam_role.agent_query_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
