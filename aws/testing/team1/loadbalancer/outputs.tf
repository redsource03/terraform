output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.alb.target_groups
}
output "security_group_id" {
  description = "ID of the security group"
  value       = module.alb.security_group_id
}