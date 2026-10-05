# Terraform AWS Modules

[![CI](https://github.com/alef2509/terraform-aws-modules/actions/workflows/ci.yml/badge.svg)](https://github.com/alef2509/terraform-aws-modules/actions/workflows/ci.yml)
![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.10-7B42BC)
![AWS provider 6](https://img.shields.io/badge/AWS%20provider-6.x-FF9900)
![License: MIT](https://img.shields.io/badge/License-MIT-blue)

Reusable, tested Terraform modules for running containerized Spring Boot
microservices on AWS: networking, load balancing, ECS Fargate, PostgreSQL,
Kafka and keyless CI/CD. They are consumed by
[aws-infra-live](https://github.com/alef2509/aws-infra-live), which deploys the
[event-driven e-commerce saga](https://github.com/alef2509/ecommerce-microservices-kafka-saga).

| Module | What it creates | Highlights |
|---|---|---|
| [network](modules/network) | VPC, public/private subnets, NAT, S3 endpoint, flow logs | NAT strategy per environment: `none` / `single` / `one_per_az` |
| [alb](modules/alb) | Application Load Balancer, listeners, security group | HTTPS with TLS 1.3 policy and HTTP redirect when a certificate is given |
| [ecs-cluster](modules/ecs-cluster) | ECS cluster, capacity providers | Optional Fargate Spot share with a guaranteed on-demand base |
| [ecs-service](modules/ecs-service) | Fargate service, task definition, IAM roles, target group, autoscaling | Deployment circuit breaker with rollback, read-only root FS, secrets injected by ECS, Graviton |
| [rds-postgres](modules/rds-postgres) | RDS PostgreSQL, parameter and subnet groups | Password managed by Secrets Manager (never in state), TLS enforced, logical replication for CDC |
| [msk-serverless](modules/msk-serverless) | MSK Serverless cluster | IAM-only auth plus a least-privilege client policy output |
| [github-oidc](modules/github-oidc) | GitHub OIDC provider, IAM role | Keyless GitHub Actions, trust pinned to repo/branch/environment |

## Design principles

- **Secure by default, configurable by intent.** Private tasks and databases,
  encryption at rest, TLS enforced, least-privilege IAM, no static credentials.
  Costly hardening (Multi-AZ, NAT per AZ, KMS CMKs, WAF, enhanced monitoring) is
  one variable away, so dev stays cheap and prod stays safe.
- **Inputs are validated.** Wrong sizes, names or wildcard OIDC subjects fail at
  `plan`, with a readable message.
- **Small surface.** Each module does one job and exposes the outputs the next
  one needs (`security_group_id`, `listener_arn`, `client_policy_json`...).

## Quality gates

| Gate | Tool | Runs in CI |
|---|---|---|
| Formatting | `terraform fmt -check` | ✓ |
| Unit tests | `terraform test` with **mocked AWS provider**: 25 tests, no credentials, no cost | ✓ (one job per module) |
| Integration | `examples/complete` composes every module and must `validate` | ✓ |
| Lint | `tflint` with the AWS ruleset | ✓ |
| Security / compliance | `checkov`: 220 checks passed, 0 failed | ✓ |
| Docs | `terraform-docs`; CI fails if a README is stale | ✓ |

### Security exceptions are explicit

Checkov findings that are deliberate choices are suppressed **on the resource,
with the reason**, never globally:

```hcl
resource "aws_db_instance" "this" {
  # checkov:skip=CKV_AWS_157: Multi-AZ is configurable (var.multi_az); off by default to keep dev cheap
  ...
```

## Example

[`examples/complete`](examples/complete) wires one service end to end:
network → ALB → ECS cluster → RDS (secrets injected into the task) → MSK
Serverless (IAM policy on the task role) → GitHub OIDC role.

```bash
cd examples/complete
terraform init -backend=false && terraform validate
```

## Cost drivers

Nothing in this repository is applied by CI. When applied, the resources billed
per hour even when idle are: NAT gateways, the load balancer, RDS instances,
Fargate tasks and MSK Serverless partitions. The main levers are
`nat_gateway_mode = "none"` (plus VPC endpoints), `fargate_spot_weight`,
`cpu_architecture = "ARM64"`, a burstable `instance_class`, and `multi_az = false` outside production.

## Running the checks locally

```bash
terraform fmt -check -recursive
for m in modules/*/; do (cd "$m" && terraform init -backend=false >/dev/null && terraform test); done
tflint --init && tflint --recursive --config "$PWD/.tflint.hcl"
docker run --rm -v "$PWD:/tf" -w /tf bridgecrew/checkov -d . --framework terraform --compact
```

## Versioning

Releases follow semantic versioning; consumers pin a tag:
`source = "git::https://github.com/alef2509/terraform-aws-modules.git//modules/network?ref=v1.0.0"`.

## License

[MIT](LICENSE)
