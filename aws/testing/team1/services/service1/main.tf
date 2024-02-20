provider "aws" {
  region = var.region
}

locals {
  container_name = "hello-world-java"
  container_port = 8080
  name = "hello-world-java-service"
  namespace = "team1-ns"
  tags = var.tags
}
module "security-groups" {
   source  = "../../security-group"
   vpc-cidr-block = module.vpc.vpc_cidr_block
   vpc-id = module.vpc.vpc_id
}
module "ecs_cluster" {
  source  = "../../cluster"
}
module "vpc" {
  source = "../../vpc"
}
module "alb" {
  source = "../../loadbalancer"
  alb-sg-id = module.security-groups.alb_sg_id
  public-subnets = module.vpc.public_subnets
  vpc-id = module.vpc.vpc_id
}
module "ecs_service" {
  source = "../../../modules/ecs-service"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  cpu    = 256
  memory = 512

  # Enables ECS Exec
  enable_execute_command = true
  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.namespace.name
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }
  }
  # Container definition(s)
  container_definitions = {
    (local.container_name) = {
      readonly_root_filesystem = false
      cpu                      = 256
      memory                   = 512
      essential                = true
      image                    = "redsource/simple-web-java:latest"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
          {"name":"API_HOST", "value": "http://hello-world-java-2:8080" },
          {"name":"CONTEXT_PATH", "value": "/app1" },
          {"name":"API_CONTEXT_PATH", "value": "/app2" }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["hello-world-tg"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_ids = [module.security-groups.services_sg_id]
  security_group_rules = {
    allow_internal_api_call = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.security-groups.services_sg_id
    }
  }

  service_tags = {
    "ServiceTag" = "Tag on service level"
  }

  tags = local.tags
}

resource "aws_service_discovery_http_namespace" "namespace" {
  name        = local.namespace
  description = "team1-service-ns"
}