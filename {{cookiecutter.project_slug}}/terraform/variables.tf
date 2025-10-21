# ==============================================================================
# 입력 변수 정의
# ==============================================================================

# 프로젝트 기본 정보
variable "project_name" {
  description = "프로젝트 이름 (리소스 이름에 사용)"
  type        = string
  default     = "{{cookiecutter.project_slug}}"
}

variable "environment" {
  description = "환경 (dev=개발용, prod=프로덕션)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "{{cookiecutter.aws_region}}"
}

# 데이터베이스 설정
variable "db_username" {
  description = "PostgreSQL 사용자명"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL 비밀번호"
  type        = string
  sensitive   = true
  default     = "change-this-password"  # terraform apply -var="db_password=실제비밀번호" 로 덮어쓰기
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "{{cookiecutter.project_slug}}"
}

# 인스턴스 크기 (환경별 자동 선택)
locals {
  # 프로젝트 이름 정규화 (언더스코어를 하이픈으로 변경)
  project_name_normalized = replace(var.project_name, "_", "-")

  # dev: 작고 저렴, prod: 크고 안정적
  db_instance_class = var.environment == "dev" ? "db.t3.micro" : "db.t3.small"
  redis_node_type   = var.environment == "dev" ? "cache.t3.micro" : "cache.t3.small"
  ecs_instance_type = var.environment == "dev" ? "t3.small" : "t3.medium"

  # 공통 태그
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
