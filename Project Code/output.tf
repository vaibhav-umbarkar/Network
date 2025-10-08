# ALB DNS Name
output "alb_dns_name" {
    description = "DNS name of the ALB"
    value = aws_lb.app_alb.dns_name
}

# ALB ARN
output "app_tg_arn" {
    description = "ARN of the Application Load Balancer Target Group"
    value = aws_lb_target_group.app_tg.arn
}

# VPC ID
output "vpc_id" {
    description = "VPC ID"
    value = aws_vpc.main_vpc.id
}

# Private Subnet 1 IDs
output "private_instance_1_id" {
    description = "Private Instance 1 ID"
    value = aws_instance.private_instance_1.id
}

# Private Subnet 2 IDs
output "private_instance_2_id" {
    description = "Private Instance 2 ID"
    value = aws_instance.private_instance_2.id
}
