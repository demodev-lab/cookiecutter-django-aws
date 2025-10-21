# ==============================================================================
# ECR (Docker 이미지 저장소)
# ==============================================================================

# ECR 리포지토리 생성
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"  # 같은 태그 덮어쓰기 가능

  # 이미지 스캔 (보안 취약점 검사)
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr-${var.environment}"
  }
}

# ECR 라이프사이클 정책 (오래된 이미지 자동 삭제)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "최근 10개 이미지만 유지"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
