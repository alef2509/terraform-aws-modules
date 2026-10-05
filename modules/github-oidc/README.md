# Github OIDC

Keyless CI/CD: GitHub OIDC provider and an IAM role that GitHub Actions workflows assume with short-lived tokens, restricted by audience and by repository/branch/environment subject. No AWS access keys stored in GitHub.

## Usage

```hcl
module "github_plan_role" {
  source = "git::https://github.com/alef2509/terraform-aws-modules.git//modules/github-oidc?ref=v1.0.0"

  role_name           = "github-terraform-plan"
  subjects            = ["repo:alef2509/aws-infra-live:pull_request"]
  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
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
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| role\_name | Name of the IAM role assumed by GitHub Actions. | `string` | n/a | yes |
| subjects | Allowed OIDC subjects, e.g. "repo:alef2509/aws-infra-live:ref:refs/heads/main"<br/>or "repo:alef2509/aws-infra-live:environment:prod". Wildcards (*) are allowed<br/>but should never cover a whole organization. | `list(string)` | n/a | yes |
| create\_oidc\_provider | Create the GitHub OIDC provider (only one per AWS account; set false if it already exists). | `bool` | `true` | no |
| inline\_policy\_json | Inline policy for the role. | `string` | `null` | no |
| managed\_policy\_arns | Managed policies attached to the role. | `list(string)` | `[]` | no |
| max\_session\_duration | Maximum session length in seconds. | `number` | `3600` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| oidc\_provider\_arn | ARN of the GitHub OIDC provider. |
| role\_arn | Role ARN to use in aws-actions/configure-aws-credentials (role-to-assume). |
<!-- END_TF_DOCS -->
