# RDS Postgres

PostgreSQL on RDS: master password generated and rotated by Secrets Manager (never in Terraform state), encrypted gp3 storage with autoscaling, TLS enforced, slow query logging, Performance Insights, final snapshot always taken, optional logical replication for change data capture (Debezium).

## Usage

```hcl
module "orders_db" {
  source = "git::https://github.com/alef2509/terraform-aws-modules.git//modules/rds-postgres?ref=v1.0.0"

  identifier                 = "shop-orders"
  database_name              = "orders"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  allowed_security_group_ids = [module.order_service.security_group_id]
  enable_logical_replication = true
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
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_role.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_ingress_rule.clients](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_iam_policy_document.monitoring_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| database\_name | Name of the initial database. | `string` | n/a | yes |
| identifier | Identifier of the DB instance. | `string` | n/a | yes |
| subnet\_ids | Private subnets (at least two AZs). | `list(string)` | n/a | yes |
| vpc\_id | VPC of the database. | `string` | n/a | yes |
| allocated\_storage | Initial storage in GiB (gp3). | `number` | `20` | no |
| allowed\_security\_group\_ids | Security groups allowed to connect on 5432 (e.g. the ECS services). | `list(string)` | `[]` | no |
| backup\_retention\_days | Automated backup retention. | `number` | `7` | no |
| deletion\_protection | Block deletion; when false a final snapshot is still taken. | `bool` | `true` | no |
| enable\_logical\_replication | Set rds.logical\_replication=1, required for change data capture (Debezium outbox relay). | `bool` | `false` | no |
| engine\_version | Major PostgreSQL version. | `string` | `"17"` | no |
| instance\_class | Instance size. Graviton burstable classes are the cheapest for dev. | `string` | `"db.t4g.micro"` | no |
| kms\_key\_arn | Customer managed KMS key for storage and Performance Insights (optional; AWS managed key otherwise). | `string` | `null` | no |
| master\_username | Master user. Its password is generated and rotated by Secrets Manager, never stored in Terraform state. | `string` | `"app_admin"` | no |
| max\_allocated\_storage | Storage autoscaling ceiling in GiB. | `number` | `100` | no |
| monitoring\_interval | Enhanced monitoring interval in seconds (0 disables; 1, 5, 10, 15, 30 or 60). | `number` | `0` | no |
| multi\_az | Synchronous standby in another AZ (production). | `bool` | `false` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| address | Hostname of the instance. |
| endpoint | host:port of the instance. |
| jdbc\_url | JDBC URL for Spring Boot (TLS required). |
| master\_user\_secret\_arn | Secrets Manager secret holding the master username and password (JSON keys: username, password). |
| port | Port of the instance. |
| security\_group\_id | Security group of the database. |
<!-- END_TF_DOCS -->
