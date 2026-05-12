# ---------------------------------------------------------------------------
# Empaquetado: ejecutar `make get-volleyball-data-build` antes del apply
# ---------------------------------------------------------------------------
data "archive_file" "get_volleyball_data_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/get_volleyball_data/package"
  output_path = "${path.module}/../backend/get_volleyball_data/lambda_function.zip"
}

# ---------------------------------------------------------------------------
# IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "get_volleyball_data_lambda" {
  name = "icesi-score-get-volleyball-data-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "get_volleyball_data_vpc_exec" {
  role       = aws_iam_role.get_volleyball_data_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ---------------------------------------------------------------------------
# Lambda Function
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "get_volleyball_data" {
  filename         = data.archive_file.get_volleyball_data_zip.output_path
  source_code_hash = data.archive_file.get_volleyball_data_zip.output_base64sha256

  function_name = "icesi-score-get-volleyball-data"
  role          = aws_iam_role.get_volleyball_data_lambda.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  depends_on = [aws_iam_role_policy_attachment.get_volleyball_data_vpc_exec]

  vpc_config {
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.icesi_score.address
      DB_PORT     = tostring(aws_db_instance.icesi_score.port)
      DB_NAME     = aws_db_instance.icesi_score.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
    }
  }
}

# ---------------------------------------------------------------------------
# API Gateway — GET /matches/{id}/volleyball-data
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "get_volleyball_data_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_volleyball_data.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_volleyball_data_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "GET /matches/{id}/volleyball-data"
  target             = "integrations/${aws_apigatewayv2_integration.get_volleyball_data_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_get_volleyball_data" {
  statement_id  = "AllowAPIGatewayInvokeGetVolleyballData"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_volleyball_data.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}
