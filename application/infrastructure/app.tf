provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    region = var.aws_region
    bucket = var.remote_state_bucket
    key    = var.remote_state_key
  }
}

data "template_file" "ecs_task_definition_template" {
  template = "${file("task_definition.json")}"

  vars {
    task_definition_name    = var.ecs_service_name
    docker_image_url        = var.docker_image_url
    docker_container_port   = var.docker_container_port
    ecs_service_name        = var.ecs_service_name
    memory                  = var.memory
    spring_profile          = var.spring_profile
    region                  = var.aws_region
  }
}

resource "aws_ecs_task_definition" "springboot-task-task-definition" {
  container_definitions         = data.template_file.ecs_task_definition_template.rendered
  family                        = var.ecs_service_name
  requires_compatibilities      = ["FARGATE"]
  network_mode                  = "awsvpc"
  execution_role_arn            = aws_iam_role.fargate_iam_role.arn
  task_role_arn                 = aws_iam_role.fargate_iam_role.arn
  cpu                           = 512
  memory                        = var.memory 
}

resource "aws_iam_role" "fargate_iam_role" {
  name = "${var.ecs_service_name}-iam-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
        }
      },
    ]
  })

  tags = {
    tag-key = "${var.ecs_service_name}-iam-role"
  }
}

resource "aws_iam_role_policy" "fargate_iam_policy" {
  name = "t${var.ecs_service_name}-iam-role-polcy"
  role = aws_iam_role.fargate_iam_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
        "ecs:*",
        "ecr:*",
        "logs:*",
        "cloudwatch:*",
        "elasticloadbalancing:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_security_group" "app-security-group" {
  name = "${var.ecs_service_name}-sg"
  description = "secuirty group for ecs app springboot"
  vpc_id = data.terraform_remote_state.platform.vpc_id
  ingress {
    from_port  = 80
    to_port    = 80
    protocol   = "TCP"
    cidr_blocks = [ data.terraform_remote_state.platform.outputs.cidr_blocks ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.ecs_service_name}-SG"
  }
}

resource "aws_alb_target_group" "ecs_app_target_group" {
  name = "${var.ecs_service_name}-TG"
  port = var.docker_container_port
  protocol = "HTTP"
  vpc_id = data.terraform_remote_state.platform.vpc_id

  health_check {
    path                = "/actuator/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = "60"
    timeout             = "30"
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags = {
    Name = "${var.ecs_service_name}-TG"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name = var.ecs_service_name
  task_definition = var.ecs_service_name
  desired_count = var.desired_task_number
  cluster = data.terraform_remote_state.platform.ecs-cluster-name
  launch_type = "FARGATE"

  network_configuration {
    subnets           = data.terraform_remote_state.platform.outputs.ecs_public_subnets
    security_groups   = [aws_security_group.app-security-group.id]
    assign_public_ip  = true
  }

  load_balancer {
    container_name   = var.ecs_service_name
    container_port   = var.docker_container_port
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
  }
}

resource "aws_alb_listener_rule" "ecs_alb_listener_rule" {
  listener_arn = data.terraform_remote_state.platform.outputs.ecs_alb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
  }

  condition {
    path_pattern {
        values = ["/*"]
    }
  }
}

resource "aws_cloudwatch_log_group" "springboot_app_log_group" {
  name = "${var.ecs_service_name}-LogGroup"
}

