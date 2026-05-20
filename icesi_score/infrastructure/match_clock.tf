# ---------------------------------------------------------------------------
# post_match_period  — POST /admin/match-periods
# put_match_period   — PUT  /admin/match-periods/{id}
# patch_match_finish — PATCH /admin/matches/{id}/finish
# All three are outside the VPC (same rationale as post_soccer_event)
# to reach SNS without a NAT Gateway.
# ---------------------------------------------------------------------------

# ── post_match_period ──────────────────────────────────────────────────────

data "archive_file" "post_match_period_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/post_match_period/package"
  output_path = "${path.module}/../backend/post_match_period/lambda_function.zip"
}

resource "aws_iam_role" "post_match_period_lambda" {
  name = "icesi-score-post-match-period-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "post_match_period_basic_exec" {
  role       = aws_iam_role.post_match_period_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "post_match_period_sns" {
  name = "post-match-period-sns-policy"
  role = aws_iam_role.post_match_period_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.ws_broadcast.arn
    }]
  })
}

resource "aws_lambda_function" "post_match_period" {
  filename         = data.archive_file.post_match_period_zip.output_path
  source_code_hash = data.archive_file.post_match_period_zip.output_base64sha256
  function_name    = "icesi-score-post-match-period"
  role             = aws_iam_role.post_match_period_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  depends_on       = [aws_iam_role_policy_attachment.post_match_period_basic_exec]

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

resource "aws_apigatewayv2_integration" "post_match_period_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.post_match_period.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_match_period_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "POST /admin/match-periods"
  target             = "integrations/${aws_apigatewayv2_integration.post_match_period_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_post_match_period" {
  statement_id  = "AllowAPIGatewayInvokePostMatchPeriod"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_match_period.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}

# ── put_match_period ───────────────────────────────────────────────────────

data "archive_file" "put_match_period_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/put_match_period/package"
  output_path = "${path.module}/../backend/put_match_period/lambda_function.zip"
}

resource "aws_iam_role" "put_match_period_lambda" {
  name = "icesi-score-put-match-period-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "put_match_period_basic_exec" {
  role       = aws_iam_role.put_match_period_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "put_match_period_sns" {
  name = "put-match-period-sns-policy"
  role = aws_iam_role.put_match_period_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.ws_broadcast.arn
    }]
  })
}

resource "aws_lambda_function" "put_match_period" {
  filename         = data.archive_file.put_match_period_zip.output_path
  source_code_hash = data.archive_file.put_match_period_zip.output_base64sha256
  function_name    = "icesi-score-put-match-period"
  role             = aws_iam_role.put_match_period_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  depends_on       = [aws_iam_role_policy_attachment.put_match_period_basic_exec]

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

resource "aws_apigatewayv2_integration" "put_match_period_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.put_match_period.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "put_match_period_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "PUT /admin/match-periods/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.put_match_period_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_put_match_period" {
  statement_id  = "AllowAPIGatewayInvokePutMatchPeriod"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.put_match_period.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}

# ── patch_match_finish ─────────────────────────────────────────────────────

data "archive_file" "patch_match_finish_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/patch_match_finish/package"
  output_path = "${path.module}/../backend/patch_match_finish/lambda_function.zip"
}

resource "aws_iam_role" "patch_match_finish_lambda" {
  name = "icesi-score-patch-match-finish-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "patch_match_finish_basic_exec" {
  role       = aws_iam_role.patch_match_finish_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "patch_match_finish_sns" {
  name = "patch-match-finish-sns-policy"
  role = aws_iam_role.patch_match_finish_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.ws_broadcast.arn
    }]
  })
}

resource "aws_lambda_function" "patch_match_finish" {
  filename         = data.archive_file.patch_match_finish_zip.output_path
  source_code_hash = data.archive_file.patch_match_finish_zip.output_base64sha256
  function_name    = "icesi-score-patch-match-finish"
  role             = aws_iam_role.patch_match_finish_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  depends_on       = [aws_iam_role_policy_attachment.patch_match_finish_basic_exec]

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

resource "aws_apigatewayv2_integration" "patch_match_finish_integration" {
  api_id                 = aws_apigatewayv2_api.icesi_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.patch_match_finish.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "patch_match_finish_route" {
  api_id             = aws_apigatewayv2_api.icesi_api.id
  route_key          = "PATCH /admin/matches/{id}/finish"
  target             = "integrations/${aws_apigatewayv2_integration.patch_match_finish_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "api_gw_patch_match_finish" {
  statement_id  = "AllowAPIGatewayInvokePatchMatchFinish"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.patch_match_finish.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.icesi_api.execution_arn}/*/*"
}
