mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "eu-west-1" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_resource "aws_msk_serverless_cluster" {
    defaults = { arn = "arn:aws:kafka:eu-west-1:123456789012:cluster/shop/1a2b3c-4d" }
  }
}

variables {
  name                       = "shop"
  vpc_id                     = "vpc-123"
  subnet_ids                 = ["subnet-a", "subnet-b"]
  allowed_security_group_ids = ["sg-order", "sg-payment"]
}

run "iam_authentication_only" {
  command = plan

  assert {
    condition     = aws_msk_serverless_cluster.this.client_authentication[0].sasl[0].iam[0].enabled
    error_message = "clients must authenticate with IAM"
  }
  assert {
    condition     = alltrue([for r in aws_vpc_security_group_ingress_rule.clients : r.from_port == 9098])
    error_message = "only the SASL/IAM TLS port should be open"
  }
}

run "client_policy_is_scoped_to_this_cluster" {
  command = apply

  assert {
    condition     = local.cluster_uuid == "1a2b3c-4d"
    error_message = "cluster uuid not derived from the ARN"
  }
  assert {
    condition     = local.arn_prefix == "arn:aws:kafka:eu-west-1:123456789012"
    error_message = "unexpected ARN prefix"
  }
}
