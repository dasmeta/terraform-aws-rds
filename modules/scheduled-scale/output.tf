output "target" {
  value       = aws_appautoscaling_target.this
  description = "The auto scale target data"
}

output "scheduled_action" {
  value       = aws_appautoscaling_scheduled_action.this
  description = "The auto scale scheduled_action data"
}

output "policy" {
  value       = aws_appautoscaling_policy.this
  description = "The auto scale policy data"
}
