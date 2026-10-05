mock_provider "aws" {}

variables {
  name = "shop"
}

run "regular_fargate_by_default" {
  command = plan

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.this.default_capacity_provider_strategy) == 1
    error_message = "only FARGATE should be in the default strategy when Spot is disabled"
  }
}

run "mixes_in_spot_when_requested" {
  command = plan

  variables {
    fargate_spot_weight = 70
  }

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.this.default_capacity_provider_strategy) == 2
    error_message = "FARGATE_SPOT should join the default strategy"
  }
}
