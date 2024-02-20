provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  tags = var.tags
  cluster_name = "team1-cluster"
}

################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = "../../modules/cluster"
  cluster_name = local.cluster_name
  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}
