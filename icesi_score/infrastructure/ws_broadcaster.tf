# ---------------------------------------------------------------------------
# ws_broadcaster — Lambda fuera de VPC para DynamoDB + WebSocket broadcast
# post_soccer_event la invoca asincrónicamente (InvocationType=Event)
# ---------------------------------------------------------------------------
data "archive_file" "ws_broadcaster_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/ws_broadcaster/package"
  output_path = "${path.module}/../backend/ws_broadcaster/lambda_function.zip"
}

resource "aws_iam_role" "ws_broadcaster_lambda" {
  name = "icesi-score-ws-broadcaster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ws_broadcaster_basic_exec" {
  role       = aws_iam_role.ws_broadcaster_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ws_broadcaster_ddb_ws" {
  name = "ws-broadcaster-ddb-ws-policy"
  role = aws_iam_role.ws_broadcaster_lambda.id
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

resource "aws_lambda_function" "ws_broadcaster" {
  filename         = data.archive_file.ws_broadcaster_zip.output_path
  source_code_hash = data.archive_file.ws_broadcaster_zip.output_base64sha256
  function_name    = "icesi-score-ws-broadcaster"
  role             = aws_iam_role.ws_broadcaster_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 10
  memory_size      = 128
  depends_on       = [aws_iam_role_policy_attachment.ws_broadcaster_basic_exec]

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.ws_connections.name
      WS_ENDPOINT    = "https://${aws_apigatewayv2_api.icesi_ws_api.id}.execute-api.${var.region}.amazonaws.com/${aws_apigatewayv2_stage.ws_default.name}"
    }
  }
}
