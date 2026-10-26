output "vpc_id" {
  description = "The ID of the custom VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "The public DNS URL of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "The connection endpoint for the private MySQL RDS database"
  value       = aws_db_instance.rds.endpoint
  sensitive   = true
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "cloudwatch_dashboard_url" {
  description = "URL to access the CloudWatch monitoring dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-dashboard"
}

