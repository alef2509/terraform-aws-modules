# ECS Cluster

ECS cluster with Container Insights and FARGATE / FARGATE_SPOT capacity providers. Spot can take a share of the tasks while one base task always stays on regular Fargate.

## Usage

```hcl
module "cluster" {
  source = "git::https://github.com/alef2509/terraform-aws-modules.git//modules/ecs-cluster?ref=v1.0.0"

  name                = "shop-dev"
  fargate_spot_weight = 70 # dev: most tasks on Spot
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
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| name | Name of the cluster. | `string` | n/a | yes |
| container\_insights | CloudWatch Container Insights: "disabled", "enabled" or "enhanced". | `string` | `"enabled"` | no |
| fargate\_spot\_weight | Share of tasks placed on FARGATE\_SPOT (up to 70% cheaper, can be interrupted). 0 disables Spot; 1 base task always stays on regular Fargate. | `number` | `0` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | ARN of the cluster. |
| name | Name of the cluster. |
<!-- END_TF_DOCS -->
