mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.0.0.0/16" }
  }
  mock_resource "aws_lb_listener" {
    defaults = { arn = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:listener/app/test/1/1" }
  }
}

variables {
  name       = "shop"
  vpc_id     = "vpc-123"
  subnet_ids = ["subnet-a", "subnet-b"]
}

run "http_only_without_certificate" {
  command = plan

  assert {
    condition     = length(aws_lb_listener.https) == 0 && aws_lb_listener.http.default_action[0].type == "fixed-response"
    error_message = "without a certificate only an HTTP listener with a 404 default is expected"
  }
  assert {
    condition     = aws_lb.this.drop_invalid_header_fields
    error_message = "invalid headers must be dropped (request smuggling protection)"
  }
}

run "https_with_redirect_when_certificate_is_given" {
  command = plan

  variables {
    certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/abc"
  }

  assert {
    condition     = length(aws_lb_listener.https) == 1 && aws_lb_listener.http.default_action[0].type == "redirect"
    error_message = "with a certificate, HTTP must redirect to an HTTPS listener"
  }
  assert {
    condition     = aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "HTTPS must use a TLS 1.2+/1.3 policy"
  }
}

run "egress_is_limited_to_the_vpc" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_egress_rule.to_targets.cidr_ipv4 == "10.0.0.0/16"
    error_message = "the load balancer should only reach targets inside the VPC"
  }
}

run "needs_two_availability_zones" {
  command = plan

  variables {
    subnet_ids = ["subnet-a"]
  }

  expect_failures = [var.subnet_ids]
}
