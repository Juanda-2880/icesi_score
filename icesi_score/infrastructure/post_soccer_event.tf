# ---------------------------------------------------------------------------
# Empaquetado: copiar psycopg2 de otro lambda antes del apply
#   cp -r backend/get_soccer_events/package/psycopg2 backend/post_soccer_event/package/
# ---------------------------------------------------------------------------
data "archive_file" "post_soccer_event_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/post_soccer_event/package"
  output_path = "${path.module}/../backend/post_soccer_event/lambda_function.zip"
}

resource "aws_iam_role" "post_soccer_event_lambda" {
  name = "icesi-score-post-soccer-event-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "post_soccer_event_basic_exec" {
  role       = aws_iam_role.post_soccer_event_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "post_soccer_event_ddb_ws" {
  name = "post-soccer-event-ddb-ws-policy"
  role = aws_iam_role.post_soccer_event_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Scan", "dynamodb:DeleteItem"]
        Resource = aws_dynamodb_table.ws_connections.arn
      },
      {
        Effect   = "Allow"
        Action   = ["execute-api:ManageConnections"]
        Resource = "${aws_apigatewayv2_api.icesi_ws_api.execution_arn}/*"
      },
    ]
  })
}

resource "aws_lambda_function" "post_soccer_event" {
  filename         = data.archive_file.post_soccer_event_zip.output_path
  source_code_hash = data.archive_file.post_soccer_event_zip.output_base64sha256
  function_name    = "icesi-score-post-soccer-event"
  role             = aws_iam_role.post_soccer_event_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  depends_on       = [aws_iam_role_policy_attachment.post_soccer_event_basic_exec]

  environment {
    variables = {
      DB_HOST         = aws_db_instance.icesi_score.address
      DB_PORT         = tostring(aws_db_instance.icesi_score.port)
      DB_NAME         = aws_db_instance.icesi_score.db_name
      DB_USER         = var.db_username
      DB_PASSWORD     = var.db_password
      DDB_TABLE          = aws_dynamodb_table.ws_connections.name
      WS_API_ENDPOINT    = "https://${aws_apigatewayv2_api.icesi_ws_api.id}.execute-api.${var.region}.amazonaws.com/${aws_apigatewayv2_stage.ws_default.name}"
      SNS_BROADCAST_ARN  = aws_sns_topic.ws_broadcast.arn
    }
  }
}

resource "aws_apigatewayv2_integration" "post_soccer_event_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.post_soccer_event.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_soccer_event_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "POST /matches/{id}/soccer-events"
  target             = "integrations/${aws_apigatewayv2_integration.post_soccer_event_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_iam_role_policy" "post_soccer_event_sns" {
  name = "publish-to-sns"
  role = aws_iam_role.post_soccer_event_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.ws_broadcast.arn
    }]
  })
}

resource "aws_lambda_permission" "api_gw_post_soccer_event" {
  statement_id  = "AllowAPIGatewayInvokePostSoccerEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_soccer_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}
