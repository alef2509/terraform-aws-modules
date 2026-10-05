data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_security_group" "this" {
  # checkov:skip=CKV2_AWS_5: attached to the MSK Serverless cluster (vpc_config), which Checkov does not resolve
  name_prefix = "${var.name}-msk-"
  description = "MSK Serverless ${var.name}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-msk" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "clients" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "Kafka clients (SASL/IAM over TLS)"
  ip_protocol                  = "tcp"
  from_port                    = 9098
  to_port                      = 9098
  referenced_security_group_id = each.value
}

# Serverless: no brokers to size or patch, pay per partition-hour and GB.
# Authentication is IAM only, so access is governed by the clients' task roles.
resource "aws_msk_serverless_cluster" "this" {
  cluster_name = var.name

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.this.id]
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

  tags = var.tags
}

locals {
  cluster_uuid = element(split("/", aws_msk_serverless_cluster.this.arn), length(split("/", aws_msk_serverless_cluster.this.arn)) - 1)
  arn_prefix   = "arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}"
}

# Least-privilege policy for application clients: produce/consume on any topic
# of this cluster and manage their own consumer groups.
data "aws_iam_policy_document" "client" {
  statement {
    sid       = "Connect"
    actions   = ["kafka-cluster:Connect", "kafka-cluster:DescribeCluster"]
    resources = [aws_msk_serverless_cluster.this.arn]
  }

  statement {
    sid = "Topics"
    actions = [
      "kafka-cluster:DescribeTopic", "kafka-cluster:CreateTopic",
      "kafka-cluster:ReadData", "kafka-cluster:WriteData",
    ]
    resources = ["${local.arn_prefix}:topic/${var.name}/${local.cluster_uuid}/*"]
  }

  statement {
    sid       = "ConsumerGroups"
    actions   = ["kafka-cluster:AlterGroup", "kafka-cluster:DescribeGroup"]
    resources = ["${local.arn_prefix}:group/${var.name}/${local.cluster_uuid}/*"]
  }
}
