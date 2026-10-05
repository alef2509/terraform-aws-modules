# ECS Service

Fargate service: task definition (Graviton by default, read-only root filesystem, secrets injected by ECS), least-privilege execution and task roles, security group reachable only from the load balancer, path-based ALB rule, deployment circuit breaker with automatic rollback, and CPU target-tracking autoscaling.

## Usage

```hcl
module "order_service" {
  source = "git::https://github.com/alef2509/terraform-aws-modules.git//modules/ecs-service?ref=v1.0.0"

  name           = "order-service"
  cluster_arn    = module.cluster.arn
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.private_subnet_ids
  image          = "ghcr.io/alef2509/order-service@sha256:..."
  container_port = 8081

  environment = { DB_URL = module.orders_db.jdbc_url }
  secrets = {
    DB_USERNAME = "${module.orders_db.master_user_secret_arn}:username::"
    DB_PASSWORD = "${module.orders_db.master_user_secret_arn}:password::"
  }

  load_balancer = {
    listener_arn      = module.alb.listener_arn
    security_group_id = module.alb.security_group_id
    path_patterns     = ["/api/v1/orders", "/api/v1/orders/*"]
    priority          = 10
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.10 |
| aws | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.0, < 7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_load_balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_iam_policy_document.ecs_tasks_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| cluster\_arn | ECS cluster that runs the service. | `string` | n/a | yes |
| image | Container image, ideally pinned by digest (repo@sha256:...). | `string` | n/a | yes |
| name | Name of the service (also the container name). | `string` | n/a | yes |
| subnet\_ids | Private subnets for the tasks. | `list(string)` | n/a | yes |
| vpc\_id | VPC of the tasks. | `string` | n/a | yes |
| additional\_security\_group\_ids | Extra security groups for the tasks. | `list(string)` | `[]` | no |
| autoscaling | Target tracking on average CPU. | <pre>object({<br/>    min_capacity       = number<br/>    max_capacity       = number<br/>    target_cpu_percent = number<br/>  })</pre> | <pre>{<br/>  "max_capacity": 6,<br/>  "min_capacity": 2,<br/>  "target_cpu_percent": 60<br/>}</pre> | no |
| container\_port | Port the container listens on. | `number` | `8080` | no |
| cpu | Task CPU units (256 = 0.25 vCPU). | `number` | `512` | no |
| cpu\_architecture | ARM64 (Graviton, ~20% cheaper) or X86\_64. | `string` | `"ARM64"` | no |
| desired\_count | Initial number of tasks (autoscaling adjusts it afterwards). | `number` | `2` | no |
| environment | Plain environment variables. | `map(string)` | `{}` | no |
| health\_check\_path | HTTP path used by the load balancer health check. | `string` | `"/actuator/health/readiness"` | no |
| kms\_key\_arn | Customer managed KMS key for the log group (optional). | `string` | `null` | no |
| load\_balancer | Attach to an ALB listener with path-based routing. Null for workers without HTTP traffic. | <pre>object({<br/>    listener_arn      = string<br/>    security_group_id = string<br/>    path_patterns     = list(string)<br/>    priority          = number<br/>  })</pre> | `null` | no |
| log\_retention\_days | Retention of the container logs. | `number` | `30` | no |
| memory | Task memory in MiB (must be compatible with cpu). | `number` | `1024` | no |
| secrets | Environment variables read at start from Secrets Manager or SSM Parameter Store: NAME => ARN (a Secrets Manager ARN may end with :json-key::). | `map(string)` | `{}` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |
| task\_role\_policy\_json | IAM policy for the application itself (e.g. Kafka or S3 access). Null for no extra permissions. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| execution\_role\_arn | Role used by ECS to pull the image, write logs and read secrets. |
| log\_group\_name | CloudWatch log group of the containers. |
| security\_group\_id | Security group of the tasks; allow it on databases and brokers. |
| service\_name | Name of the ECS service. |
| target\_group\_arn | Target group, when attached to a load balancer. |
| task\_role\_arn | Role assumed by the application code. |
<!-- END_TF_DOCS -->
