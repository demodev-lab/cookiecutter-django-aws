# ==============================================================================
# Application Load Balancer (트래픽 분산)
# ==============================================================================

# ALB 생성
resource "aws_lb" "main" {
  name               = "${local.project_name_normalized}-alb-${var.environment}"
  internal           = false  # 외부 접근 가능
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${replace(var.project_name, "_", "-")}-alb-${var.environment}"
  }
}

# Target Group (ECS 컨테이너로 트래픽 전달)
resource "aws_lb_target_group" "app" {
  name        = "${local.project_name_normalized}-tg-${var.environment}"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"  # Fargate 또는 awsvpc 네트워크 모드 사용 시 ip

  # 헬스체크 (Django /health/ 엔드포인트)
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${replace(var.project_name, "_", "-")}-tg-${var.environment}"
  }
}

# Listener (HTTP 트래픽을 Target Group으로 전달)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
