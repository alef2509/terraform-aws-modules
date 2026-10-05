mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = { names = ["eu-west-1a", "eu-west-1b", "eu-west-1c"] }
  }
  mock_data "aws_region" {
    defaults = { region = "eu-west-1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

variables {
  name = "test"
}

run "splits_the_vpc_into_public_and_private_subnets_per_az" {
  command = plan

  variables {
    az_count = 3
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3
    error_message = "expected one public and one private subnet per AZ"
  }
  assert {
    condition     = aws_subnet.public[0].cidr_block == "10.0.0.0/20" && aws_subnet.private[0].cidr_block == "10.0.128.0/20"
    error_message = "unexpected subnet layout"
  }
  assert {
    condition     = alltrue([for s in aws_subnet.public : !s.map_public_ip_on_launch])
    error_message = "public subnets must not auto-assign public IPs"
  }
}

run "single_nat_is_shared_by_all_private_route_tables" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route.private_nat) == 2
    error_message = "single mode must create one NAT and route both AZs through it"
  }
}

run "one_nat_per_az_for_high_availability" {
  command = plan

  variables {
    nat_gateway_mode = "one_per_az"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "one_per_az must create a NAT per AZ"
  }
}

run "no_nat_means_no_default_route" {
  command = plan

  variables {
    nat_gateway_mode = "none"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat) == 0 && length(aws_eip.nat) == 0
    error_message = "none must not create NAT gateways, EIPs or default routes"
  }
}

run "flow_logs_capture_rejected_traffic" {
  command = plan

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "REJECT"
    error_message = "flow logs should capture rejected traffic"
  }
}

run "rejects_invalid_inputs" {
  command = plan

  variables {
    name             = "Invalid_Name"
    az_count         = 5
    nat_gateway_mode = "two"
  }

  expect_failures = [var.name, var.az_count, var.nat_gateway_mode]
}
