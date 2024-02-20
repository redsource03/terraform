output "alb_sg_id" {
  value       =  aws_security_group.team1-alb-sg.id
}

output "services_sg_id" {
  value       =  aws_security_group.services-sg.id
}