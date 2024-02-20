output "arn" {
  description = "ARN that identifies the cluster"
  value       = try(module.ecs_cluster.arn, null)
}

output "cluster_name" {
  description = "cluster name"
  value       = local.cluster_name
}