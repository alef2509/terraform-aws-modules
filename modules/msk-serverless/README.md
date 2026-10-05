# MSK Serverless

Amazon MSK Serverless (Kafka without brokers to size or patch) with IAM authentication only, plus a least-privilege client policy scoped to this cluster's topics and consumer groups, ready to attach to task roles.

## Usage

```hcl
module "kafka" {
  source = "git::https://github.com/alef2509/terraform-aws-modules.git//modules/msk-serverless?ref=v1.0.0"

  name                       = "shop-dev"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  allowed_security_group_ids = [module.order_service.security_group_id]
}

# then: task_role_policy_json = module.kafka.client_policy_json
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
| [aws_msk_serverless_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_serverless_cluster) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_ingress_rule.clients](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| name | Name of the MSK Serverless cluster. | `string` | n/a | yes |
| subnet\_ids | Private subnets (at least two AZs). | `list(string)` | n/a | yes |
| vpc\_id | VPC of the cluster. | `string` | n/a | yes |
| allowed\_security\_group\_ids | Security groups of the Kafka clients. | `list(string)` | `[]` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | ARN of the cluster. |
| bootstrap\_brokers\_sasl\_iam | Bootstrap servers for SASL/IAM clients. |
| client\_policy\_json | IAM policy to attach to the task roles of producers and consumers. |
| security\_group\_id | Security group of the cluster. |
<!-- END_TF_DOCS -->
