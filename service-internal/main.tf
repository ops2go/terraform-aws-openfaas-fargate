resource "aws_ecs_service" "main" {
    name             = "${var.name}"
    cluster          = "${var.ecs_cluster_name}"
    task_definition  = "${aws_ecs_task_definition.main.arn}"
    launch_type      = "FARGATE"
    desired_count    = "${var.desired_count}"

    network_configuration {
        subnets          = ["${var.allowed_subnets}"]
        security_groups  = ["${var.security_groups}"]
        assign_public_ip = false
    }

    service_registries {
        registry_arn = "${var.service_discovery_service_arn}"
    }

    lifecycle {
        ignore_changes = ["desired_count"]
    }
}

resource "aws_ecs_task_definition" "main" {
    family                   = "${var.name}"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    task_role_arn            = "${var.task_role_arn}"
    execution_role_arn       = "${var.task_role_arn}"
    cpu                      = "256"
    memory                   = "512"
    container_definitions    = <<DEFINITION
[
  {
    "cpu": ${var.task_cpu},
    "environment": ${var.task_env_vars},
    "essential": true,
    "image": "${var.task_image}:${var.task_image_version}",
    "memory": ${var.task_memory},
    "name": "${var.name}",
    "portMappings": ${var.task_ports},
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.main.name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "gateway"
        }
    },
    "name": "gateway",
    "healthCheck": {
        "retries": 1,
        "command": [
            "CMD-SHELL",
            "ls"
        ],
        "timeout": 3,
        "interval": 5,
        "startPeriod": 5
    }
}
]
DEFINITION
}

resource "aws_cloudwatch_log_group" "main" {
    name = "${var.namespace}-${var.name}"
}