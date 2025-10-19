# Django AWS Cookiecutter Template - 진행상황

**마지막 업데이트:** 2025-10-19 (Windows WSL에서 작업 중)

---

## 프로젝트 개요

Django 5.2.7 + AWS ECS 배포를 위한 **프로덕션급 Cookiecutter 템플릿**

**핵심 목표:** 실제 서비스가 AWS에서 돌아가도록 만들기

**기술 스택:**
- Django 5.2.7 + Django REST Framework + JWT 인증
- AWS S3 Presigned URL (파일 업로드/다운로드)
- Docker Compose (로컬 개발)
- PostgreSQL, Redis, Celery, WebSocket (Channels)
- uv 패키지 매니저
- **ECS on EC2** (프로덕션 배포)
- **Terraform** (인프라 관리)
- **GitHub Actions** (CI/CD)

---

## 완료된 작업 ✅

### Phase 1: 로컬 개발 환경 (완료)
- ✅ Cookiecutter 템플릿 기본 구조
- ✅ Docker Compose 6개 서비스 설정
  - PostgreSQL 16
  - Redis 7
  - Django Backend (DRF + JWT)
  - WebSocket (Daphne)
  - Celery Worker
  - Celery Beat
- ✅ S3 Presigned URL 전략 설정
- ✅ Celery 설정 파일 추가 (`config/celery.py`, `config/__init__.py`)
- ✅ .env 파일 위치 변경 (프로젝트 루트)
- ✅ README.md 문서화
- ✅ macOS + Windows WSL 테스트 완료

**커밋 내역:**
- `fb24848` - Initial cookiecutter Django AWS template
- `4191508` - Add Celery configuration files

---

## 현재 작업 중 🚧

### Phase 2: AWS 프로덕션 배포 준비

**목표:** Terraform으로 AWS 인프라 자동 생성

---

## 다음 작업 계획 📋

### 작업 1: Terraform 인프라 코드 작성

**디렉토리 구조:**
```
{{cookiecutter.project_slug}}/
├── terraform/
│   ├── README.md              # 사용자 가이드 (로컬 실행 방법)
│   ├── main.tf                # 메인 설정
│   ├── variables.tf           # 입력 변수
│   ├── outputs.tf             # 출력값 (ALB URL, ECR 등)
│   ├── vpc.tf                 # VPC, 서브넷, 인터넷 게이트웨이
│   ├── s3.tf                  # S3 버킷 (미디어 파일)
│   ├── rds.tf                 # PostgreSQL 데이터베이스
│   ├── elasticache.tf         # Redis
│   ├── ecr.tf                 # Docker 이미지 저장소
│   ├── ecs.tf                 # ECS 클러스터 + Task Definitions
│   ├── alb.tf                 # Application Load Balancer
│   ├── iam.tf                 # IAM 역할/정책
│   └── security.tf            # 보안 그룹
```

**생성될 AWS 리소스:**
1. **S3 버킷** - 미디어 파일 저장 (`{project_slug}-media-{environment}`)
2. **VPC** - 격리된 네트워크 (Public/Private 서브넷)
3. **RDS PostgreSQL** - 프로덕션 데이터베이스
4. **ElastiCache Redis** - 캐시 + Celery 브로커
5. **ECR** - Docker 이미지 저장소
6. **ECS Cluster + EC2** - 컨테이너 실행 환경
7. **Application Load Balancer** - 트래픽 분산
8. **IAM Roles** - ECS Task 실행 권한

**중요 설정:**
```hcl
# S3 버킷 - 개발/프로덕션 환경 분리
resource "aws_s3_bucket" "media" {
  bucket = "${var.project_slug}-media-${var.environment}"

  # 개발: 파일 포함 삭제 가능
  # 프로덕션: 보호
  force_destroy = var.environment == "dev" ? true : false
}

# 개발 환경: 30일 후 파일 자동 삭제
resource "aws_s3_bucket_lifecycle_configuration" "media_dev" {
  count  = var.environment == "dev" ? 1 : 0

  rule {
    id     = "delete-old-files"
    status = "Enabled"
    expiration {
      days = 30
    }
  }
}
```

**사용자 워크플로우:**
```bash
# 1. 프로젝트 생성
cookiecutter cookiecutter-django-aws/

# 2. AWS 인프라 생성 (최초 1회)
cd my_project/terraform/
terraform init
terraform plan     # 생성될 리소스 미리보기
terraform apply    # 실제 생성 (5~10분 소요)

# 3. 출력값 확인
terraform output
# → alb_url, ecr_repository, s3_bucket_name 등

# 4. 개발 완료 후 삭제
terraform destroy  # 모든 리소스 삭제
```

---

### 작업 2: GitHub Actions CI/CD 설정

**디렉토리 구조:**
```
{{cookiecutter.project_slug}}/
├── .github/
│   └── workflows/
│       └── deploy.yml         # 애플리케이션 배포
```

**역할 분리:**
- **Terraform** (로컬 실행): 인프라 생성/삭제 (최초 1회 + 인프라 변경 시)
- **GitHub Actions** (자동 실행): 애플리케이션 배포 (코드 푸시할 때마다)

**deploy.yml 워크플로우:**
```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # 1. Docker 이미지 빌드
      - name: Build Backend
        run: docker build -t backend:latest ./backend

      # 2. ECR에 푸시
      - name: Push to ECR
        run: |
          aws ecr get-login-password | docker login ...
          docker tag backend:latest $ECR_REPO:$GITHUB_SHA
          docker push $ECR_REPO:$GITHUB_SHA

      # 3. ECS 서비스 업데이트
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster $CLUSTER_NAME \
            --service $SERVICE_NAME \
            --force-new-deployment
```

**필요한 GitHub Secrets:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
ECR_REPOSITORY          # terraform output에서 가져옴
ECS_CLUSTER_NAME        # terraform output에서 가져옴
ECS_SERVICE_NAME        # terraform output에서 가져옴
```

---

### 작업 3: 문서화

**파일:**
- `terraform/README.md` - Terraform 사용 가이드
- `docs/deployment.md` - 배포 가이드
- 프로젝트 `README.md` 업데이트

---

## 작업 순서 (체크리스트)

### Step 1: Terraform 파일 작성
- [ ] `terraform/README.md` - 사용자 가이드
- [ ] `terraform/variables.tf` - 변수 정의
- [ ] `terraform/main.tf` - Provider 설정
- [ ] `terraform/vpc.tf` - VPC, 서브넷, IGW
- [ ] `terraform/s3.tf` - S3 버킷 (force_destroy 설정 포함)
- [ ] `terraform/rds.tf` - PostgreSQL
- [ ] `terraform/elasticache.tf` - Redis
- [ ] `terraform/ecr.tf` - Docker 이미지 저장소
- [ ] `terraform/ecs.tf` - ECS 클러스터 + Task Definitions
- [ ] `terraform/alb.tf` - Load Balancer
- [ ] `terraform/iam.tf` - IAM 역할/정책
- [ ] `terraform/security.tf` - 보안 그룹
- [ ] `terraform/outputs.tf` - 출력값

### Step 2: GitHub Actions 설정
- [ ] `.github/workflows/deploy.yml` - 배포 워크플로우
- [ ] 환경변수 관리 (Secrets Manager 참조)

### Step 3: 테스트
- [ ] 로컬에서 Terraform 테스트
  ```bash
  cookiecutter .
  cd test-output/my_django_project/terraform/
  terraform init
  terraform plan
  terraform apply  # 실제 AWS 리소스 생성
  terraform destroy
  ```
- [ ] GitHub Actions 테스트 (실제 레포 생성해서)

### Step 4: 문서화
- [ ] Terraform README 작성
- [ ] 배포 가이드 작성
- [ ] 프로젝트 README 업데이트

### Step 5: 커밋
- [ ] Git add & commit
- [ ] Git push

---

## 환경 설정

### 로컬 개발 환경 (Windows WSL)
```bash
# 현재 위치
/home/surkim/cookiecutter-django-aws/

# Git 설정 완료
user.name: surokim
user.email: ksro0128@naver.com

# 최신 커밋
4191508 - Add Celery configuration files

# 테스트 프로젝트
test-output/my_django_project/  # Docker Compose 실행 중
```

### 필요한 도구
- ✅ Git
- ✅ Docker + Docker Compose
- ✅ cookiecutter
- ⬜ Terraform (설치 필요)
- ⬜ AWS CLI (설치 필요)

---

## 중요 개념 정리

### 1. Terraform vs GitHub Actions

| 항목 | Terraform | GitHub Actions |
|------|----------|---------------|
| **역할** | AWS 인프라 생성/관리 | 애플리케이션 배포 |
| **실행 위치** | 로컬 | GitHub 서버 |
| **실행 빈도** | 최초 1회 + 인프라 변경 시 | 코드 푸시할 때마다 |
| **명령어** | `terraform apply` | `git push` (자동) |
| **생성 대상** | S3, RDS, ECS 클러스터 등 | Docker 이미지, ECS 서비스 업데이트 |

### 2. 환경 분리 전략

**개발 환경 (dev):**
- S3 `force_destroy = true` → 파일 포함 삭제 가능
- 30일 후 파일 자동 삭제
- 작은 인스턴스 타입
- 자유롭게 생성/삭제

**프로덕션 환경 (prod):**
- S3 `force_destroy = false` → 데이터 보호
- Lifecycle 보호 정책
- 큰 인스턴스 타입
- 삭제 전 수동 확인 필요

### 3. ECS Task Definition

6개 컨테이너를 ECS에서 실행:
1. Backend (Django)
2. WebSocket (Daphne)
3. Celery Worker
4. Celery Beat
5. PostgreSQL → RDS로 대체
6. Redis → ElastiCache로 대체

---

## 시작하기 (내일 작업 시)

```bash
# 1. 프로젝트 열기
cd /home/surkim/cookiecutter-django-aws/

# 2. Git 최신 상태 확인
git status
git log --oneline -3

# 3. PROGRESS.md 읽기
cat PROGRESS.md

# 4. Terraform 디렉토리 생성
mkdir -p {{cookiecutter.project_slug}}/terraform/

# 5. Terraform 파일 작성 시작
# - README.md부터 작성 (사용자 가이드)
# - variables.tf (변수 정의)
# - main.tf (Provider 설정)
# - vpc.tf, s3.tf, rds.tf 등...
```

---

## 참고 자료

**Terraform AWS Provider:**
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs

**주요 리소스 문서:**
- [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [aws_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster)
- [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition)
- [aws_db_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- [aws_elasticache_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster)
- [aws_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)

---

**작업 환경:**
- Windows 11 + WSL2
- Git 레포: github.com:demodev-lab/cookiecutter-django-aws.git
- 브랜치: main
