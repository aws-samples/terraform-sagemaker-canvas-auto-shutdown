data "aws_caller_identity" "current" {}

data "archive_file" "canvas_auto_shutdown_lambda" {
  type = "zip"

  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/canvas_auto_shutdown.zip"
}

resource "aws_lambda_function" "canvas_auto_shutdown" {
  function_name = "CanvasAutoShutdown"
  filename      = "canvas_auto_shutdown.zip"

  runtime = var.python_runtime
  handler = "canvas_auto_shutdown.lambda_handler"
  
  environment {
    variables = {
      TIMEOUT_THRESHOLD = var.timeout_threshold
      ALARM_PERIOD = var.alarm_period
    }
  }

  source_code_hash = data.archive_file.canvas_auto_shutdown_lambda.output_base64sha256

  role = aws_iam_role.canvas_auto_shutdown_lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "canvas_auto_shutdown" {
  name = "/aws/lambda/${aws_lambda_function.canvas_auto_shutdown.function_name}"

  retention_in_days = var.cloudwatch_retention_period
}

resource "aws_iam_role" "canvas_auto_shutdown_lambda_exec" {
  name = "canvas_auto_shutdown_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution_policy" {
  role       = aws_iam_role.canvas_auto_shutdown_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "canvas_auto_shutdown_policy" {
  name = "canvas_auto_shutdown_policy"
  role = aws_iam_role.canvas_auto_shutdown_lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:GetMetricData",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sagemaker:DeleteApp",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:app/*/*/canvas/default"
      },
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "canvas_idle_alarm" {
  alarm_name                = "canvas_idle_alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  threshold                 = var.timeout_threshold
  alarm_description         = "Alarm when TimeSinceLastActive exceeds 2 hours"
  treat_missing_data        = "notBreaching"  
  
  metric_query {
    id          = "q1"
    label       = "Find the highest timeout across all of the user profiles"
    period      = var.alarm_period
    expression  = "SELECT MAX(TimeSinceLastActive) FROM \"/aws/sagemaker/Canvas/AppActivity\""
    return_data = true
  }
}

resource "aws_cloudwatch_event_rule" "canvas_auto_shutdown" {
  name        = "canvas_auto_shutdown"
  description = "Rule that executes a Lambda function whenever the Alarm is triggered"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ],
    detail-type = [
      "CloudWatch Alarm State Change"
    ],
    resources = [
       aws_cloudwatch_metric_alarm.canvas_idle_alarm.arn
    ]
  })
}

resource "aws_cloudwatch_event_target" "canvas_auto_shutdown" {
  target_id = "canvas_auto_shutdown"
  rule      = aws_cloudwatch_event_rule.canvas_auto_shutdown.name
  arn       = aws_lambda_function.canvas_auto_shutdown.arn
}

resource "aws_lambda_permission" "allow_event_bridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.canvas_auto_shutdown.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.canvas_auto_shutdown.arn
}