# ---------------------------------------------------------------------------
# Empaquetado: ejecutar `make create-admin-user-build` antes del apply
# ---------------------------------------------------------------------------
data "archive_file" "create_admin_user_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/create_admin_user/package"
  output_path = "${path.module}/../backend/create_admin_user/lambda_function.zip"
}

# ---------------------------------------------------------------------------
# IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "create_admin_user_lambda" {
  name = "icesi-score-create-admin-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "create_admin_user_basic_exec" {
  role       = aws_iam_role.create_admin_user_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "create_admin_user_cognito" {
  name = "icesi-score-create-admin-user-cognito-policy"
  role = aws_iam_role.create_admin_user_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "cognito-idp:AdminCreateUser"
      Resource = aws_cognito_user_pool.icesi_score_pool.arn
    }]
  })
}

# ---------------------------------------------------------------------------
# Lambda Function
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "create_admin_user" {
  filename         = data.archive_file.create_admin_user_zip.output_path
  source_code_hash = data.archive_file.create_admin_user_zip.output_base64sha256

  function_name = "icesi-score-create-admin-user"
  role          = aws_iam_role.create_admin_user_lambda.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  depends_on = [
    aws_iam_role_policy_attachment.create_admin_user_basic_exec,
    aws_iam_role_policy.create_admin_user_cognito,
  ]

  environment {
    variables = {
      DB_HOST              = aws_db_instance.icesi_score.address
      DB_PORT              = tostring(aws_db_instance.icesi_score.port)
      DB_NAME              = aws_db_instance.icesi_score.db_name
      DB_USER              = var.db_username
      DB_PASSWORD          = var.db_password
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.icesi_score_pool.id
    }
  }
}
