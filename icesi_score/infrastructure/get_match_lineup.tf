# ---------------------------------------------------------------------------
# Empaquetado: copiar psycopg2 de otro lambda antes del apply
#   cp -r backend/get_soccer_events/package/psycopg2 backend/get_match_lineup/package/
# ---------------------------------------------------------------------------
data "archive_file" "get_match_lineup_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/get_match_lineup/package"
  output_path = "${path.module}/../backend/get_match_lineup/lambda_function.zip"
}

resource "aws_iam_role" "get_match_lineup_lambda" {
  name = "icesi-score-get-match-lineup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "get_match_lineup_vpc_exec" {
  role       = aws_iam_role.get_match_lineup_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "get_match_lineup" {
  filename         = data.archive_file.get_match_lineup_zip.output_path
  source_code_hash = data.archive_file.get_match_lineup_zip.output_base64sha256
  function_name    = "icesi-score-get-match-lineup"
  role             = aws_iam_role.get_match_lineup_lambda.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 128
  depends_on       = [aws_iam_role_policy_attachment.get_match_lineup_vpc_exec]

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

resource "aws_apigatewayv2_integration" "get_match_lineup_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_match_lineup.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_match_lineup_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "GET /matches/{id}/lineup"
  target             = "integrations/${aws_apigatewayv2_integration.get_match_lineup_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_get_match_lineup" {
  statement_id  = "AllowAPIGatewayInvokeGetMatchLineup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_match_lineup.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}
