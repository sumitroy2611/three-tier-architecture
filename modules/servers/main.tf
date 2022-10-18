/*
* Launch templates & ASG configuration for frontend app server
*/

resource "aws_launch_template" "web_app" {
  name_prefix            = "web_app"
  instance_type          = var.instance_type
  image_id               = var.ami_id
  vpc_security_group_ids = [var.frontend_app_sg]
  user_data              = filebase64("install_webapp.sh")
  key_name               = var.key_name

  tags = {
    Name = "web_app"
  }
}

resource "aws_autoscaling_group" "web_app" {
  name                = "web_app"
  vpc_zone_identifier = var.private_subnets
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.web_app.id
    version = "$Latest"
  }

  depends_on = [
    aws_launch_template.web_app
  ]
}


/*
* Launch templates & ASG configuration for application server
*/

resource "aws_launch_template" "app_backend" {
  name_prefix            = "app_backend"
  instance_type          = var.instance_type
  image_id               = var.ami_id
  vpc_security_group_ids = [var.backend_app_sg]
  key_name               = var.key_name
  user_data              = filebase64("install_backend.sh")

  tags = {
    Name = "app_backend"
  }
}

resource "aws_autoscaling_group" "app_backend" {
  name                = "app_backend"
  vpc_zone_identifier = var.private_subnets
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.app_backend.id
    version = "$Latest"
  }

  depends_on = [
    aws_launch_template.app_backend
  ]
}

/*
*
*/
resource "aws_launch_template" "bastion_host" {
  name_prefix            = "bastion_host"
  instance_type          = var.instance_type
  image_id               = var.ami_id
  vpc_security_group_ids = [var.bastion_sg]
  key_name               = var.key_name

  tags = {
    Name = "bastion_host"
  }
}

resource "aws_autoscaling_group" "three_tier_bastion" {
  name                = "bastion_host"
  vpc_zone_identifier = var.public_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.bastion_host.id
    version = "$Latest"
  }
}

/*
* Application load balancer
*/

#application load balancer config
resource "aws_lb" "app_lb" {
  name            = "app-loadbalancer"
  security_groups = [var.lb_sg]
  subnets         = var.public_subnets
  idle_timeout    = 400

  depends_on = [
    aws_autoscaling_group.web_app
  ]
}

#Configuring the target group for the ALB
resource "aws_lb_target_group" "app_tg" {
  name     = "lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

#Configuring the target group listener
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

/*
* ASG attachment to the load balancer for app tier
*/

#Attaching the load balancer target group to ASG
resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.web_app.id
  lb_target_group_arn    = aws_lb_target_group.app_tg.arn
}
