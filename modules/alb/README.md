# ALB

Public Application Load Balancer. With a certificate it serves HTTPS (TLS 1.2/1.3) and redirects HTTP; without one it serves HTTP only. Default action is a JSON 404; services add their own path rules. Egress restricted to the VPC, invalid headers dropped.

## Usage

```hcl
module "alb" {
  source = "git::https://github.com/alef2509/terraform-aws-modules.git//modules/alb?ref=v1.0.0"

  name            = "shop-dev"
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.public_subnet_ids
  certificate_arn = aws_acm_certificate.this.arn
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
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.to_targets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| name | Name of the load balancer (max 32 characters). | `string` | n/a | yes |
| subnet\_ids | Public subnets (at least two AZs). | `list(string)` | n/a | yes |
| vpc\_id | VPC where the load balancer lives. | `string` | n/a | yes |
| access\_logs\_bucket | S3 bucket for access logs (optional; the bucket policy must allow the ELB service). | `string` | `null` | no |
| certificate\_arn | ACM certificate. When set, HTTPS is served on 443 and HTTP redirects to it; when null, only HTTP on 80 (demo environments). | `string` | `null` | no |
| deletion\_protection | Prevent accidental deletion (enable in production). | `bool` | `false` | no |
| idle\_timeout | Idle connection timeout, in seconds. | `number` | `60` | no |
| ingress\_cidr\_blocks | Client CIDRs allowed to reach the load balancer. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| ssl\_policy | TLS policy of the HTTPS listener. | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| tags | Tags applied to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | ARN of the load balancer. |
| dns\_name | Public DNS name of the load balancer. |
| listener\_arn | Listener where services attach their routing rules (HTTPS when a certificate is set, else HTTP). |
| security\_group\_id | Security group of the load balancer; allow it on the targets. |
| zone\_id | Route 53 zone of the load balancer, for alias records. |
<!-- END_TF_DOCS -->
