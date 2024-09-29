variable "aws_region" {
  default = "ap-south-1"
}

variable "remote_state_bucket" {
    description = "remote_state_bucket"
}

variable "remote_state_key" {
    description = "remote_state_key"
}

variable "ecs-cluster-name" {
    description = "ecs-cluster-name"
}
