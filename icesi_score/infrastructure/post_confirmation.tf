# ---------------------------------------------------------------------------
# Empaquetado: el Makefile (lambda-build) construye package/ antes del apply
# ---------------------------------------------------------------------------
data "archive_file" "post_confirmation_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/post_confirmation/package"
  output_path = "${path.module}/../backend/post_confirmation/lambda_function.zip"
}

# ---------------------------------------------------------------------------
# IAM Role para la Lambda
# ---------------------------------------------------------------------------
resource "aws_iam_role" "post_confirmation_lambda" {
  name = "icesi-score-post-confirmation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# AWSLambdaVPCAccessExecutionRole = CloudWatch Logs + gestión de ENIs para VPC
resource "aws_iam_role_policy_attachment" "post_confirmation_vpc_exec" {
  role       = aws_iam_role.post_confirmation_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ---------------------------------------------------------------------------
# Lambda Function (psycopg2 incluido en el zip, sin layers externas)
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "post_confirmation" {
  filename         = data.archive_file.post_confirmation_zip.output_path
  source_code_hash = data.archive_file.post_confirmation_zip.output_base64sha256

  function_name = "icesi-score-post-confirmation"
  role          = aws_iam_role.post_confirmation_lambda.arn

  # Espera a que el IAM role y su policy estén completamente propagados
  depends_on = [aws_iam_role_policy_attachment.post_confirmation_vpc_exec]
  handler       = "lambda_function.handler"
  runtime       = "python3.11"
  timeout       = 10

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
# Permiso: Cognito puede invocar esta Lambda
# ---------------------------------------------------------------------------
resource "aws_lambda_permission" "cognito_invoke_post_confirmation" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.icesi_score_pool.arn
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "post_confirmation_lambda_arn" {
  description = "ARN de la Lambda PostConfirmation vinculada al trigger de Cognito"
  value       = aws_lambda_function.post_confirmation.arn
}
