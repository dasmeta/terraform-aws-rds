## This terraform sub-module allows to create rds aurora cluster scheduled auto scaling

### basic example

```terraform
module "rds_schedule_auto_scale" {
    source  = "dasmeta/rds/aws//modules/scheduled-scale"
    version = "1.70.0"

    target = {
        resource_id  = "cluster:my-test-cluster"
        min_capacity = 1
        max_capacity = 2
    }
    scheduled_actions = [
        {
          name         = "scale_down_daily"
          schedule     = "cron(00 22 * * ? *)" # every day at 22:00 scale down read replicas to 0
          min_capacity = 0
          max_capacity = 0
          timezone     = "Europe/Berlin"
        },
        {
          name         = "scale_up_daily"
          schedule     = "cron(00 08 * * ? *)" # every day at 08:00 morning scale up read replicas min=1, max=2
          min_capacity = 1
          max_capacity = 2
          timezone     = "Europe/Berlin"
        }
    ]
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_scheduled_action.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_scheduled_action) | resource |
| [aws_appautoscaling_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_policy"></a> [policy](#input\_policy) | App auto scaling policy configs | <pre>object({<br/>    name                                         = string<br/>    policy_type                                  = string<br/>    step_scaling_policy_configuration            = optional(any, null)<br/>    target_tracking_scaling_policy_configuration = optional(any, null)<br/>  })</pre> | `null` | no |
| <a name="input_scheduled_actions"></a> [scheduled\_actions](#input\_scheduled\_actions) | App auto scaling configs | <pre>list(object({<br/>    name               = string                 # the name sof scheduled scale<br/>    schedule           = string                 # the schedule time to apply auto scale, can be cron(min hour day month week-day year ), at(yyyy-mm-ddThh:mm:ss) or rate(value unit) formats<br/>    min_capacity       = optional(number, null) # if not set defaults to target min_capacity<br/>    max_capacity       = optional(number, null) # if not set defaults to target max_capacity<br/>    scalable_dimension = optional(string, "rds:cluster:ReadReplicaCount")<br/>    timezone           = optional(string, null) # by default it uses UTC, available values can be found here: https://www.joda.org/joda-time/timezones.html<br/>  }))</pre> | `[]` | no |
| <a name="input_target"></a> [target](#input\_target) | App auto scaling target configs | <pre>object({<br/>    resource_id        = string<br/>    min_capacity       = optional(number, 1)<br/>    max_capacity       = optional(number, 2)<br/>    scalable_dimension = optional(string, "rds:cluster:ReadReplicaCount")<br/>    service_namespace  = optional(string, "rds")<br/>    create             = optional(string, false) // allows to create target if it was not been created yet<br/>  })</pre> | <pre>{<br/>  "resource_id": null<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy"></a> [policy](#output\_policy) | The auto scale policy data |
| <a name="output_scheduled_action"></a> [scheduled\_action](#output\_scheduled\_action) | The auto scale scheduled\_action data |
| <a name="output_target"></a> [target](#output\_target) | The auto scale target data |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
