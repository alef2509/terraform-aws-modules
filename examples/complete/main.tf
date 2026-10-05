# Composes every module into a minimal production-like stack for one service.
# Used by CI to validate that the modules fit together; nothing here is applied.

provider "aws" {
  region = var.region

  default_tags {
    tags = { Project = "complete-example", ManagedBy = "terraform" }
  }
}

module "network" {
  source = "../../modules/network"

  name             = "shop"
  nat_gateway_mode = "single"
}

module "alb" {
  source = "../../modules/alb"

  name       = "shop"
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.public_subnet_ids
}

module "cluster" {
  source = "../../modules/ecs-cluster"

  name = "shop"
}

module "kafka" {
  source = "../../modules/msk-serverless"

  name                       = "shop"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  allowed_security_group_ids = [module.order_service.security_group_id]
}

module "orders_db" {
  source = "../../modules/rds-postgres"

  identifier                 = "shop-orders"
  database_name              = "orders"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  allowed_security_group_ids = [module.order_service.security_group_id]
  deletion_protection        = false
}

module "order_service" {
  source = "../../modules/ecs-service"

  name           = "order-service"
  cluster_arn    = module.cluster.arn
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.private_subnet_ids
  image          = var.image
  container_port = 8081

  environment = {
    DB_URL                  = module.orders_db.jdbc_url
    KAFKA_BOOTSTRAP_SERVERS = module.kafka.bootstrap_brokers_sasl_iam
    OUTBOX_RELAY            = "polling"
  }
  secrets = {
    DB_USERNAME = "${module.orders_db.master_user_secret_arn}:username::"
    DB_PASSWORD = "${module.orders_db.master_user_secret_arn}:password::"
  }
  task_role_policy_json = module.kafka.client_policy_json

  load_balancer = {
    listener_arn      = module.alb.listener_arn
    security_group_id = module.alb.security_group_id
    path_patterns     = ["/api/v1/orders", "/api/v1/orders/*"]
    priority          = 10
  }
}

module "github_actions" {
  source = "../../modules/github-oidc"

  role_name           = "github-terraform-plan"
  subjects            = ["repo:alef2509/aws-infra-live:pull_request"]
  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}
