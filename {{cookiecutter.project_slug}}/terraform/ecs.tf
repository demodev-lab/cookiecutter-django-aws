# ==============================================================================
# ECS (컨테이너 실행 환경)
# ==============================================================================

# ECS 클러스터
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.environment}"

  tags = {
    Name = "${var.project_name}-cluster-${var.environment}"
  }
}

# CloudWatch 로그 그룹 (컨테이너 로그 저장)
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.environment == "dev" ? 7 : 30  # dev: 7일, prod: 30일

  tags = {
    Name = "${var.project_name}-logs-${var.environment}"
  }
}

# ECS Task Definition (컨테이너 설정)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.environment == "dev" ? "256" : "512"   # dev: 0.25vCPU, prod: 0.5vCPU
  memory                   = var.environment == "dev" ? "512" : "1024"  # dev: 512MB, prod: 1GB

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "django"
      image = "${aws_ecr_repository.app.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "DATABASE_URL"
          value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:6379/0"
        },
        {
          name  = "AWS_STORAGE_BUCKET_NAME"
          value = aws_s3_bucket.media.bucket
        },
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "django"
        }
      }

      essential = true
    }
  ])

  tags = {
    Name = "${var.project_name}-task-${var.environment}"
  }
}

# ECS Service (컨테이너 실행 및 유지)
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.environment == "dev" ? 1 : 2  # dev: 1개, prod: 2개

  launch_type = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true  # Public 서브넷에서 외부 통신 가능
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "django"
    container_port   = 8000
  }

  # 배포 시 이전 버전과 새 버전 동시 실행
  # deployment_configuration {
  #   maximum_percent         = 200
  #   minimum_healthy_percent = 100
  # }

  tags = {
    Name = "${var.project_name}-service-${var.environment}"
  }
}
