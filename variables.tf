# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
  default = "us-east-1"
}

variable "timeout_threshold" {
  description = "Time (in seconds) that the SageMaker Canvas app is allowed to stay in idle before gets shutdown. Default value is 2 hours."
  type = number
  default = 7200
}

variable "alarm_period" {
  description = "Aggregation time (in seconds) used by CloudWatch Alarm to compute the idle timeout. Default value is 20 minutes."
  type = number
  default = 1200
}

variable "python_runtime" {
  description = "Runtime for Canvas Auto Shutdown Lambda."
  type = string
  default = "python3.11"
}

variable "cloudwatch_retention_period" {
  description = "CloudWatch Logs retention period in days."
  type = number
  default = 30
}