# ---------------------------------------------------------------------------
# DynamoDB — WebSocket connection registry
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "ws_connections" {
  name         = "icesi-score-ws-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

# ---------------------------------------------------------------------------
# WebSocket API Gateway
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "icesi_ws_api" {
  name                       = "icesi-score-ws-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "ws_default" {
  api_id      = aws_apigatewayv2_api.icesi_ws_api.id
  name        = "$default"
  auto_deploy = true
}

# ---------------------------------------------------------------------------
# Lambda: $connect
# ---------------------------------------------------------------------------
data "archive_file" "ws_connect_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/ws_connect/lambda_function.py"
  output_path = "${path.module}/../backend/ws_connect/lambda_function.zip"
}

resource "aws_iam_role" "ws_connect_lambda" {
  name = "icesi-score-ws-connect-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ws_connect_basic_exec" {
  role       = aws_iam_role.ws_connect_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ws_connect_ddb" {
  name = "ws-connect-ddb-policy"
  role = aws_iam_role.ws_connect_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem"]
      Resource = aws_dynamodb_table.ws_connections.arn
    }]
  })
}

resource "aws_lambda_function" "ws_connect" {
  filename         = data.archive_file.ws_connect_zip.output_path
  source_code_hash = data.archive_file.ws_connect_zip.output_base64sha256
  function_name    = "icesi-score-ws-connect"
  role             = aws_iam_role.ws_connect_lambda.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  timeout          = 10
  memory_size      = 128
  depends_on       = [aws_iam_role_policy_attachment.ws_connect_basic_exec]
  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.ws_connections.name
    }
  }
}

resource "aws_apigatewayv2_integration" "ws_connect_integration" {
  api_id           = aws_apigatewayv2_api.icesi_ws_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.ws_connect.invoke_arn
}

resource "aws_apigatewayv2_route" "ws_connect_route" {
  api_id             = aws_apigatewayv2_api.icesi_ws_api.id
  route_key          = "$connect"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.ws_connect_integration.id}"
}

resource "aws_lambda_permission" "ws_api_gw_connect" {
  statement_id  = "AllowWSAPIGatewayInvokeConnect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_connect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_ws_api.execution_arn}/*/*"
}

# ---------------------------------------------------------------------------
# Lambda: $disconnect
# ---------------------------------------------------------------------------
data "archive_file" "ws_disconnect_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/ws_disconnect/lambda_function.py"
  output_path = "${path.module}/../backend/ws_disconnect/lambda_function.zip"
}

resource "aws_iam_role" "ws_disconnect_lambda" {
  name = "icesi-score-ws-disconnect-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ws_disconnect_basic_exec" {
  role       = aws_iam_role.ws_disconnect_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ws_disconnect_ddb" {
  name = "ws-disconnect-ddb-policy"
  role = aws_iam_role.ws_disconnect_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:DeleteItem"]
      Resource = aws_dynamodb_table.ws_connections.arn
    }]
  })
}

resource "aws_lambda_function" "ws_disconnect" {
  filename         = data.archive_file.ws_disconnect_zip.output_path
  source_code_hash = data.archive_file.ws_disconnect_zip.output_base64sha256
  function_name    = "icesi-score-ws-disconnect"
  role             = aws_iam_role.ws_disconnect_lambda.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  timeout          = 10
  memory_size      = 128
  depends_on       = [aws_iam_role_policy_attachment.ws_disconnect_basic_exec]
  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.ws_connections.name
    }
  }
}

resource "aws_apigatewayv2_integration" "ws_disconnect_integration" {
  api_id           = aws_apigatewayv2_api.icesi_ws_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.ws_disconnect.invoke_arn
}

resource "aws_apigatewayv2_route" "ws_disconnect_route" {
  api_id    = aws_apigatewayv2_api.icesi_ws_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_disconnect_integration.id}"
}

resource "aws_lambda_permission" "ws_api_gw_disconnect" {
  statement_id  = "AllowWSAPIGatewayInvokeDisconnect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_disconnect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_ws_api.execution_arn}/*/*"
}
