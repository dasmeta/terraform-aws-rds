resource "aws_appautoscaling_target" "this" {
  count = var.target.create ? 1 : 0

  min_capacity       = var.target.min_capacity
  max_capacity       = var.target.max_capacity
  resource_id        = var.target.resource_id
  scalable_dimension = var.target.scalable_dimension
  service_namespace  = var.target.service_namespace
}

resource "aws_appautoscaling_scheduled_action" "this" {
  for_each = { for key, item in var.scheduled_actions : key => item }

  name               = each.value.name
  service_namespace  = var.target.service_namespace
  resource_id        = var.target.resource_id
  scalable_dimension = var.target.scalable_dimension
  schedule           = each.value.schedule
  timezone           = each.value.timezone

  scalable_target_action {
    min_capacity = try(each.value.min_capacity, var.target.min_capacity)
    max_capacity = try(each.value.max_capacity, var.target.max_capacity)
  }

}

resource "aws_appautoscaling_policy" "this" {
  count = var.policy == null ? 0 : 1

  name               = var.policy.name
  policy_type        = var.policy.policy_type
  resource_id        = var.target.resource_id
  scalable_dimension = var.target.scalable_dimension
  service_namespace  = var.target.service_namespace

  dynamic "step_scaling_policy_configuration" {
    for_each = var.policy.step_scaling_policy_configuration == null ? [] : [var.policy.step_scaling_policy_configuration]

    content {
      adjustment_type          = step_scaling_policy_configuration.value.adjustment_type
      cooldown                 = step_scaling_policy_configuration.value.cooldown
      metric_aggregation_type  = step_scaling_policy_configuration.value.metric_aggregation_type
      min_adjustment_magnitude = step_scaling_policy_configuration.value.min_adjustment_magnitude

      dynamic "step_adjustment" {
        for_each = step_scaling_policy_configuration.value.step_adjustment

        content {
          metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
          metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
          scaling_adjustment          = step_adjustment.value.scaling_adjustment
        }
      }
    }
  }

  dynamic "target_tracking_scaling_policy_configuration" {
    for_each = var.policy.target_tracking_scaling_policy_configuration == null ? [] : [var.policy.target_tracking_scaling_policy_configuration]

    content {
      target_value       = target_tracking_scaling_policy_configuration.value.target_value
      disable_scale_in   = target_tracking_scaling_policy_configuration.value.disable_scale_in
      scale_in_cooldown  = target_tracking_scaling_policy_configuration.scale_in_cooldown
      scale_out_cooldown = target_tracking_scaling_policy_configuration.scale_out_cooldown

      dynamic "predefined_metric_specification" {
        for_each = target_tracking_scaling_policy_configuration.value.predefined_metric_specification == null ? [] : [target_tracking_scaling_policy_configuration.value.predefined_metric_specification]

        content {
          predefined_metric_type = predefined_metric_specification.value.predefined_metric_type
          resource_label         = predefined_metric_specification.value.resource_label
        }
      }
    }
  }
}
