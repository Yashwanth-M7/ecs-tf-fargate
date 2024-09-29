resource "aws_security_group" "ecs-alb-security-groups" {
  name = "${var.ecs-cluster-name}-alb-sg"
  description = "secuirty group for ecs alb"
  vpc_id = data.terraform_remote_state.infrastructure.vpc_id

  ingress {
    from_port  = 443
    to_port    = 443
    protocol   = "TCP"
    cidr_blocks = [ data.terraform_remote_state.infrastructure.outputs.vpc_cidr_block ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ data.terraform_remote_state.infrastructure.outputs.vpc_cidr_block ]
  }

}