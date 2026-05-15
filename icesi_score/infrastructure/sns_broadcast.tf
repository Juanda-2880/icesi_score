# ---------------------------------------------------------------------------
# SNS — intermediario entre post_soccer_event (VPC) y ws_broadcaster (público)
# post_soccer_event publica en el topic; SNS invoca ws_broadcaster como suscriptor.
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "ws_broadcast" {
  name = "icesi-score-ws-broadcast"
}

resource "aws_sns_topic_subscription" "ws_broadcaster_sub" {
  topic_arn = aws_sns_topic.ws_broadcast.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ws_broadcaster.arn
}

resource "aws_lambda_permission" "sns_invoke_ws_broadcaster" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_broadcaster.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ws_broadcast.arn
}
