provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "infrastructure" {
  backend = "s3"

  config = {
    region = var.aws_region
    bucket = var.remote_state_bucket
    key    = var.remote_state_key
  }
}

resource "aws_ecs_cluster" "prod-ecs-cluster" {
  name = "prod-ecs-cluster"
}

resource "aws_alb" "ecs-cluster-alb" {
  name            = "${var.ecs-cluster-name}-alb"
  internal        = false
  security_groups = [aws_security_group.ecs-alb-security-groups.id]
  subnets         = data.terraform_remote_state.infrastructure.outputs.public_subnets

  tags = {
    Name = "${var.ecs-cluster-name}-alb"
  } 
}

resource "aws_alb_listener" "ecs_alb_https_listener" {
  load_balancer_arn = aws_alb.ecs-cluster-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_default_target_group.arn
  }

  depends_on = [aws_alb_target_group.ecs_default_target_group]
}

resource "aws_alb_target_group" "ecs_default_target_group" {
  name     = "${var.ecs-cluster-name}-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.infrastructure.outputs.vpc_id

  tags = {
    Name = "${var.ecs-cluster-name}-TG"
  }
}




############# IAM Role #############

resource "aws_iam_role" "ecs-cluster-role" {
  name = "${var.ecs-cluster-name}-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
 {
   "Effect": "Allow",
   "Principal": {
     "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "platform-autoscaling.amazonaws.com"]
   },
   "Action": "sts:AssumeRole"
  }
  ]
 }
EOF
}

resource "aws_iam_role_policy" "ecs-cluster-policy" {
  name = "ecs-cluster-policy"
  role = aws_iam_role.ecs-cluster-role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "elasticloadbalancing:*",
          "s3:*",
          "rds:*",
          "cloudwatch:*",
          "sqs:*",
          "sns:*",
          "logs:*",
          "ssm:*",
          "dynamodb:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
