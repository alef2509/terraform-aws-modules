mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "eu-west-1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/mock" }
  }
  mock_resource "aws_lb_target_group" {
    defaults = { arn = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:targetgroup/mock/1" }
  }
  mock_resource "aws_ecs_task_definition" {
    defaults = { arn = "arn:aws:ecs:eu-west-1:123456789012:task-definition/mock:1" }
  }
}

variables {
  name        = "order-service"
  cluster_arn = "arn:aws:ecs:eu-west-1:123456789012:cluster/shop"
  vpc_id      = "vpc-123"
  subnet_ids  = ["subnet-a", "subnet-b"]
  image       = "ghcr.io/alef2509/order-service@sha256:abc"
}

run "worker_without_load_balancer" {
  command = plan

  assert {
    condition     = length(aws_lb_target_group.this) == 0 && length(aws_vpc_security_group_ingress_rule.from_load_balancer) == 0
    error_message = "a worker must not get a target group nor inbound rules"
  }
  assert {
    condition     = aws_ecs_service.this.deployment_circuit_breaker[0].rollback
    error_message = "failed deployments must roll back automatically"
  }
  assert {
    condition     = !aws_ecs_service.this.network_configuration[0].assign_public_ip
    error_message = "tasks must not get public IPs"
  }
  assert {
    condition     = aws_appautoscaling_target.this.resource_id == "service/shop/order-service"
    error_message = "autoscaling must target the service in its cluster"
  }
}

run "web_service_behind_the_load_balancer" {
  command = plan

  variables {
    container_port = 8081
    load_balancer = {
      listener_arn      = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:listener/app/shop/1/1"
      security_group_id = "sg-alb"
      path_patterns     = ["/api/v1/orders*"]
      priority          = 10
    }
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.from_load_balancer[0].referenced_security_group_id == "sg-alb"
    error_message = "only the load balancer may reach the tasks"
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.from_load_balancer[0].from_port == 8081
    error_message = "ingress must be limited to the container port"
  }
  assert {
    condition     = aws_lb_target_group.this[0].health_check[0].path == "/actuator/health/readiness"
    error_message = "health checks should use the readiness probe"
  }
}

run "hardened_container_definition" {
  command = plan

  variables {
    environment = { SPRING_PROFILES_ACTIVE = "aws" }
    secrets = {
      DB_PASSWORD = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:rds!db-123-AbCdEf:password::"
      DB_USERNAME = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:rds!db-123-AbCdEf:username::"
      API_KEY     = "arn:aws:ssm:eu-west-1:123456789012:parameter/shop/api-key"
    }
  }

  assert {
    condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].readonlyRootFilesystem
    error_message = "the root filesystem must be read-only"
  }
  assert {
    condition     = contains([for s in jsondecode(aws_ecs_task_definition.this.container_definitions)[0].secrets : s.name], "DB_PASSWORD")
    error_message = "secrets must be injected by ECS, not as plain environment variables"
  }
  assert {
    condition = toset(local.secret_arns) == toset([
      "arn:aws:secretsmanager:eu-west-1:123456789012:secret:rds!db-123-AbCdEf",
      "arn:aws:ssm:eu-west-1:123456789012:parameter/shop/api-key",
    ])
    error_message = "the execution role must be scoped to the secret itself, without the JSON key suffix"
  }
}

run "rejects_invalid_sizes" {
  command = plan

  variables {
    cpu = 300
    autoscaling = {
      min_capacity       = 5
      max_capacity       = 2
      target_cpu_percent = 60
    }
  }

  expect_failures = [var.cpu, var.autoscaling]
}
