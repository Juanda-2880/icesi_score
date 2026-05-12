# ---------------------------------------------------------------------------
# Empaquetado: ejecutar `make get-match-periods-build` antes del apply
# ---------------------------------------------------------------------------
data "archive_file" "get_match_periods_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/get_match_periods/package"
  output_path = "${path.module}/../backend/get_match_periods/lambda_function.zip"
}

# ---------------------------------------------------------------------------
# IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "get_match_periods_lambda" {
  name = "icesi-score-get-match-periods-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "get_match_periods_vpc_exec" {
  role       = aws_iam_role.get_match_periods_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ---------------------------------------------------------------------------
# Lambda Function
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "get_match_periods" {
  filename         = data.archive_file.get_match_periods_zip.output_path
  source_code_hash = data.archive_file.get_match_periods_zip.output_base64sha256

  function_name = "icesi-score-get-match-periods"
  role          = aws_iam_role.get_match_periods_lambda.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  depends_on = [aws_iam_role_policy_attachment.get_match_periods_vpc_exec]

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
