################################################################################
# VPC
################################################################################

output "vpc_id" {
  value       = try(module.vpc.vpc_id, null)
}


output "vpc_cidr_block" {
  value       = try(module.vpc.vpc_cidr_block, null)
}

output "public_subnets" {
  value       = try(module.vpc.public_subnets, null)
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = try(module.vpc.private_subnets, null)
}
