output "web_app_asg" {
  value = aws_autoscaling_group.web_app
}

output "app_backend_asg" {
  value = aws_autoscaling_group.app_backend
}

output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}

output "lb_endpoint" {
  value = aws_lb.app_lb.dns_name
}

output "lb_tg" {
  value = aws_lb_target_group.app_tg.arn
}
