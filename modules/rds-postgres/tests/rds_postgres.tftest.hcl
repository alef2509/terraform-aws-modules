mock_provider "aws" {
  mock_resource "aws_db_instance" {
    defaults = {
      address            = "orders.abc.eu-west-1.rds.amazonaws.com"
      port               = 5432
      master_user_secret = [{ secret_arn = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:rds!db-1", kms_key_id = "k", secret_status = "active" }]
    }
  }
}

variables {
  identifier                 = "orders"
  vpc_id                     = "vpc-123"
  subnet_ids                 = ["subnet-a", "subnet-b"]
  database_name              = "orders"
  allowed_security_group_ids = ["sg-order-service"]
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_db_instance.this.manage_master_user_password && aws_db_instance.this.password == null
    error_message = "the password must be managed by Secrets Manager, never by Terraform"
  }
  assert {
    condition     = aws_db_instance.this.storage_encrypted && !aws_db_instance.this.publicly_accessible
    error_message = "storage must be encrypted and the instance private"
  }
  assert {
    condition     = contains([for p in aws_db_parameter_group.this.parameter : "${p.name}=${p.value}"], "rds.force_ssl=1")
    error_message = "TLS must be enforced"
  }
  assert {
    condition     = !aws_db_instance.this.skip_final_snapshot
    error_message = "a final snapshot must always be taken"
  }
}

run "only_allowed_security_groups_can_connect" {
  command = plan

  assert {
    condition     = keys(aws_vpc_security_group_ingress_rule.clients) == ["sg-order-service"]
    error_message = "ingress must be limited to the given security groups"
  }
}

run "logical_replication_for_debezium" {
  command = plan

  variables {
    enable_logical_replication = true
  }

  assert {
    condition     = contains([for p in aws_db_parameter_group.this.parameter : "${p.name}=${p.value}"], "rds.logical_replication=1")
    error_message = "logical replication must be enabled for CDC"
  }
}

run "exposes_a_tls_jdbc_url" {
  command = apply

  assert {
    condition     = output.jdbc_url == "jdbc:postgresql://orders.abc.eu-west-1.rds.amazonaws.com:5432/orders?sslmode=require"
    error_message = "unexpected JDBC URL"
  }
}
