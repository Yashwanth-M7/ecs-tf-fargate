variable "aws-region" {
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

variable "ecs_service_name" {}
variable "docker_image_url" {}
variable "docker_container_port" {}
variable "memory" {}
variable "spring_profile" {}
variable "desired_task_number" {}


