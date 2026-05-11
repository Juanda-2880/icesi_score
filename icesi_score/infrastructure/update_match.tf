# ---------------------------------------------------------------------------
# Empaquetado: ejecutar `make update-match-build` antes del apply
# ---------------------------------------------------------------------------
data "archive_file" "update_match_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/update_match/package"
  output_path = "${path.module}/../backend/update_match/lambda_function.zip"
}

# ---------------------------------------------------------------------------
# IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "update_match_lambda" {
  name = "icesi-score-update-match-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "update_match_vpc_exec" {
  role       = aws_iam_role.update_match_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ---------------------------------------------------------------------------
# Lambda Function
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "update_match" {
  filename         = data.archive_file.update_match_zip.output_path
  source_code_hash = data.archive_file.update_match_zip.output_base64sha256

  function_name = "icesi-score-update-match"
  role          = aws_iam_role.update_match_lambda.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  depends_on = [aws_iam_role_policy_attachment.update_match_vpc_exec]

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
