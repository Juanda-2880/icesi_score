# ---------------------------------------------------------------------------
# Volleyball Live Management — US-16, US-17, US-18
#   post_volleyball_set   — POST /admin/volleyball-sets
#   post_volleyball_event — POST /admin/volleyball-events
#   post_rotate_team      — POST /admin/matches/{id}/rotate-team
# All three are outside the VPC (same rationale as post_soccer_event).
# ---------------------------------------------------------------------------

# ── post_volleyball_set ────────────────────────────────────────────────────

data "archive_file" "post_volleyball_set_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/post_volleyball_set/package"
  output_path = "${path.module}/../backend/post_volleyball_set/lambda_function.zip"
}

resource "aws_iam_role" "post_volleyball_set_lambda" {
  name = "icesi-score-post-volleyball-set-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "post_volleyball_set_basic_exec" {
  role       = aws_iam_role.post_volleyball_set_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "post_volleyball_set_sns" {
  name = "post-volleyball-set-sns-policy"
  role = aws_iam_role.post_volleyball_set_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.ws_broadcast.arn
    }]
  })
}

resource "aws_lambda_function" "post_volleyball_set" {
  filename         = data.archive_file.post_volleyball_set_zip.output_path
  source_code_hash = data.archive_file.post_volleyball_set_zip.output_base64sha256
  function_name    = "icesi-score-post-volleyball-set"
  role             = aws_iam_role.post_volleyball_set_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  depends_on       = [aws_iam_role_policy_attachment.post_volleyball_set_basic_exec]

  environment {
    variables = {
      DB_HOST           = aws_db_instance.icesi_score.address
      DB_PORT           = tostring(aws_db_instance.icesi_score.port)
      DB_NAME           = aws_db_instance.icesi_score.db_name
      DB_USER           = var.db_username
      DB_PASSWORD       = var.db_password
      SNS_BROADCAST_ARN = aws_sns_topic.ws_broadcast.arn
    }
  }
}

resource "aws_apigatewayv2_integration" "post_volleyball_set_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.post_volleyball_set.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_volleyball_set_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "POST /admin/volleyball-sets"
  target             = "integrations/${aws_apigatewayv2_integration.post_volleyball_set_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_post_volleyball_set" {
  statement_id  = "AllowAPIGatewayInvokePostVolleyballSet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_volleyball_set.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}

# ── post_volleyball_event ──────────────────────────────────────────────────

data "archive_file" "post_volleyball_event_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/post_volleyball_event/package"
  output_path = "${path.module}/../backend/post_volleyball_event/lambda_function.zip"
}

resource "aws_iam_role" "post_volleyball_event_lambda" {
  name = "icesi-score-post-volleyball-event-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "post_volleyball_event_basic_exec" {
  role       = aws_iam_role.post_volleyball_event_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "post_volleyball_event_sns" {
  name = "post-volleyball-event-sns-policy"
  role = aws_iam_role.post_volleyball_event_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.ws_broadcast.arn
    }]
  })
}

resource "aws_lambda_function" "post_volleyball_event" {
  filename         = data.archive_file.post_volleyball_event_zip.output_path
  source_code_hash = data.archive_file.post_volleyball_event_zip.output_base64sha256
  function_name    = "icesi-score-post-volleyball-event"
  role             = aws_iam_role.post_volleyball_event_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  depends_on       = [aws_iam_role_policy_attachment.post_volleyball_event_basic_exec]

  environment {
    variables = {
      DB_HOST           = aws_db_instance.icesi_score.address
      DB_PORT           = tostring(aws_db_instance.icesi_score.port)
      DB_NAME           = aws_db_instance.icesi_score.db_name
      DB_USER           = var.db_username
      DB_PASSWORD       = var.db_password
      SNS_BROADCAST_ARN = aws_sns_topic.ws_broadcast.arn
    }
  }
}

resource "aws_apigatewayv2_integration" "post_volleyball_event_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.post_volleyball_event.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_volleyball_event_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "POST /admin/volleyball-events"
  target             = "integrations/${aws_apigatewayv2_integration.post_volleyball_event_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_post_volleyball_event" {
  statement_id  = "AllowAPIGatewayInvokePostVolleyballEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_volleyball_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}

# ── post_rotate_team ───────────────────────────────────────────────────────

data "archive_file" "post_rotate_team_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/post_rotate_team/package"
  output_path = "${path.module}/../backend/post_rotate_team/lambda_function.zip"
}

resource "aws_iam_role" "post_rotate_team_lambda" {
  name = "icesi-score-post-rotate-team-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "post_rotate_team_basic_exec" {
  role       = aws_iam_role.post_rotate_team_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "post_rotate_team" {
  filename         = data.archive_file.post_rotate_team_zip.output_path
  source_code_hash = data.archive_file.post_rotate_team_zip.output_base64sha256
  function_name    = "icesi-score-post-rotate-team"
  role             = aws_iam_role.post_rotate_team_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  depends_on       = [aws_iam_role_policy_attachment.post_rotate_team_basic_exec]

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

resource "aws_apigatewayv2_integration" "post_rotate_team_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.post_rotate_team.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_rotate_team_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "POST /admin/matches/{id}/rotate-team"
  target             = "integrations/${aws_apigatewayv2_integration.post_rotate_team_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_post_rotate_team" {
  statement_id  = "AllowAPIGatewayInvokePostRotateTeam"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_rotate_team.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}
