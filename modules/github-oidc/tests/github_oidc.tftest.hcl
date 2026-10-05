mock_provider "aws" {
  mock_resource "aws_iam_openid_connect_provider" {
    defaults = { arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" }
  }
  mock_data "aws_iam_openid_connect_provider" {
    defaults = { arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

variables {
  role_name = "github-terraform-plan"
  subjects  = ["repo:alef2509/aws-infra-live:pull_request"]
}

run "trust_is_restricted_to_the_repository_and_audience" {
  command = plan

  assert {
    condition     = toset(flatten([for c in data.aws_iam_policy_document.trust.statement[0].condition : c.values if c.variable == "token.actions.githubusercontent.com:sub"])) == toset(["repo:alef2509/aws-infra-live:pull_request"])
    error_message = "the trust policy must pin the subject"
  }
  assert {
    condition     = toset(flatten([for c in data.aws_iam_policy_document.trust.statement[0].condition : c.values if c.variable == "token.actions.githubusercontent.com:aud"])) == toset(["sts.amazonaws.com"])
    error_message = "the trust policy must pin the STS audience"
  }
}

run "reuses_an_existing_provider" {
  command = plan

  variables {
    create_oidc_provider = false
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "must not create a second provider in the account"
  }
}

run "refuses_organization_wide_wildcards" {
  command = plan

  variables {
    subjects = ["repo:*"]
  }

  expect_failures = [var.subjects]
}
