resource "aws_api_gateway_rest_api" "security_soar_approval" {
  name = "SecuritySOARApprovalAPI"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "approve" {
  rest_api_id = aws_api_gateway_rest_api.security_soar_approval.id
  parent_id   = aws_api_gateway_rest_api.security_soar_approval.root_resource_id
  path_part   = "approve"
}

resource "aws_api_gateway_resource" "reject" {
  rest_api_id = aws_api_gateway_rest_api.security_soar_approval.id
  parent_id   = aws_api_gateway_rest_api.security_soar_approval.root_resource_id
  path_part   = "reject"
}

resource "aws_api_gateway_method" "approve_get" {
  rest_api_id      = aws_api_gateway_rest_api.security_soar_approval.id
  resource_id      = aws_api_gateway_resource.approve.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_method" "reject_get" {
  rest_api_id      = aws_api_gateway_rest_api.security_soar_approval.id
  resource_id      = aws_api_gateway_resource.reject.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "approve_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.security_soar_approval.id
  resource_id             = aws_api_gateway_resource.approve.id
  http_method             = aws_api_gateway_method.approve_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.approval_processor.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_integration" "reject_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.security_soar_approval.id
  resource_id             = aws_api_gateway_resource.reject.id
  http_method             = aws_api_gateway_method.reject_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.approval_processor.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_method_response" "approve_200" {
  rest_api_id = aws_api_gateway_rest_api.security_soar_approval.id
  resource_id = aws_api_gateway_resource.approve.id
  http_method = aws_api_gateway_method.approve_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "reject_200" {
  rest_api_id = aws_api_gateway_rest_api.security_soar_approval.id
  resource_id = aws_api_gateway_resource.reject.id
  http_method = aws_api_gateway_method.reject_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "approve_200" {
  rest_api_id = aws_api_gateway_rest_api.security_soar_approval.id
  resource_id = aws_api_gateway_resource.approve.id
  http_method = aws_api_gateway_method.approve_get.http_method
  status_code = aws_api_gateway_method_response.approve_200.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.approve_lambda]
}

resource "aws_api_gateway_integration_response" "reject_200" {
  rest_api_id = aws_api_gateway_rest_api.security_soar_approval.id
  resource_id = aws_api_gateway_resource.reject.id
  http_method = aws_api_gateway_method.reject_get.http_method
  status_code = aws_api_gateway_method_response.reject_200.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.reject_lambda]
}

resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.security_soar_approval.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.approve.id,
      aws_api_gateway_resource.reject.id,
      aws_api_gateway_method.approve_get.id,
      aws_api_gateway_method.reject_get.id,
      aws_api_gateway_integration.approve_lambda.id,
      aws_api_gateway_integration.reject_lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_api_gateway_rest_api.security_soar_approval.id
  stage_name    = "prod"
}
