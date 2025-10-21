# Django AWS Cookiecutter Template - 진행상황

**마지막 업데이트:** 2025-10-21

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
- **ECS Fargate** (프로덕션 배포)
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
- ✅ Celery 설정 파일 추가
- ✅ .env 파일 위치 변경 (프로젝트 루트)
- ✅ README.md 문서화
- ✅ macOS + Windows WSL 테스트 완료

### Phase 2: Terraform 인프라 코드 (완료)
- ✅ **13개 Terraform 파일 작성 완료**
  - `main.tf` - Provider 설정
  - `variables.tf` - 입력 변수 정의 + 이름 정규화 로직
  - `vpc.tf` - VPC, 서브넷, 인터넷 게이트웨이
  - `security.tf` - 보안 그룹 4개 (ALB, ECS, RDS, Redis)
  - `s3.tf` - S3 버킷 + CORS + Lifecycle
  - `rds.tf` - PostgreSQL 16 (db.t3.micro/small)
  - `elasticache.tf` - Redis 7.0 (cache.t3.micro/small)
  - `ecr.tf` - Docker 이미지 저장소
  - `iam.tf` - ECS Task 권한 설정
  - `alb.tf` - Application Load Balancer
  - `ecs.tf` - ECS Fargate Task Definition + Service
  - `outputs.tf` - URL 등 출력값
  - `README.md` - Terraform 사용 가이드
- ✅ **실제 AWS 배포 테스트 성공**
  - terraform init ✅
  - terraform validate ✅
  - terraform plan ✅ (34개 리소스)
  - terraform apply ✅ (34개 리소스 생성 성공)
  - terraform destroy ✅ (완전 삭제 확인)

**생성된 AWS 리소스 (34개):**
1. VPC + Public/Private 서브넷 (6개)
2. 인터넷 게이트웨이 + 라우트 테이블 (3개)
3. 보안 그룹 4개 (ALB, ECS, RDS, Redis)
4. S3 버킷 + 설정 (4개)
5. RDS PostgreSQL + 서브넷 그룹 (2개)
6. ElastiCache Redis + 서브넷 그룹 (2개)
7. ECR + Lifecycle Policy (2개)
8. IAM 역할 2개 + 정책 2개 (4개)
9. ALB + Target Group + Listener (3개)
10. ECS Cluster + Task Definition + Service (3개)
11. CloudWatch 로그 그룹 (1개)

**주요 수정 사항:**
- 프로젝트 이름 정규화: 언더스코어(_) → 하이픈(-) 자동 변환
- AWS 리소스 이름 규칙 준수 (소문자 + 숫자 + 하이픈만)
- dev/prod 환경 분리 (인스턴스 크기, 백업, 삭제 정책)
- S3 dev 환경: force_destroy + 30일 자동 삭제
- ECS Fargate 사용 (EC2 관리 불필요)

**커밋 내역:**
- `fb24848` - Initial cookiecutter Django AWS template
- `4191508` - Add Celery configuration files
- *다음 커밋 예정* - Add Terraform infrastructure code

---

## 현재 작업 중 🚧

**없음** - Terraform 인프라 완료, 커밋 준비 중

---

## 다음 작업 계획 📋

### 작업 1: GitHub Actions CI/CD 설정

**디렉토리 구조:**
```
{{cookiecutter.project_slug}}/
├── .github/
│   └── workflows/
│       └── deploy.yml
```

**워크플로우:**
1. main 브랜치 푸시 시 자동 실행
2. Docker 이미지 빌드 (backend)
3. ECR에 푸시
4. ECS 서비스 재배포

**필요한 작업:**
- [ ] `.github/workflows/deploy.yml` 작성
- [ ] GitHub Secrets 설정 가이드
- [ ] 배포 테스트

---

## 사용 방법

### 1. 프로젝트 생성
```bash
cookiecutter cookiecutter-django-aws/
```

### 2. 로컬 개발
```bash
cd my_project/
cp .env.example .env
# .env 파일 수정 (AWS 키, DB 비밀번호 등)

docker-compose up -d
```

### 3. AWS 인프라 생성
```bash
# AWS CLI 설정
aws configure

# Terraform 실행
cd terraform/
terraform init
terraform plan
terraform apply

# 출력값 확인
terraform output
# → app_url, ecr_repository_url, s3_bucket_name 등
```

### 4. 앱 배포
```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin [ECR_URL]

# 이미지 빌드 & 푸시
docker build -t myapp ./backend
docker tag myapp:latest [ECR_URL]:latest
docker push [ECR_URL]:latest

# ECS 재배포
aws ecs update-service \
  --cluster [CLUSTER_NAME] \
  --service [SERVICE_NAME] \
  --force-new-deployment
```

### 5. 인프라 삭제
```bash
terraform destroy
```

---

## 비용 정보

### dev 환경 (월 예상)
- RDS db.t3.micro: ~$15
- ElastiCache cache.t3.micro: ~$12
- ECS Fargate (0.25vCPU, 512MB): ~$10
- ALB: ~$20
- S3, VPC, CloudWatch: ~$3
- **총 ~$60/월**

### prod 환경 (월 예상)
- RDS db.t3.small: ~$30
- ElastiCache cache.t3.small: ~$24
- ECS Fargate (0.5vCPU, 1GB, 2개): ~$30
- ALB: ~$20
- S3, VPC, CloudWatch: ~$6
- **총 ~$110/월**

**개발/테스트:**
- 10분 테스트: ~$0.01 (10원)
- 1시간: ~$0.06 (60원)
- terraform destroy로 즉시 삭제 가능

---

## 환경 설정

### 개발 환경
- macOS Sequoia 24.6.0
- Git 레포: github.com/demodev-lab/cookiecutter-django-aws.git
- 브랜치: main

### 필요한 도구
- ✅ Git
- ✅ Docker + Docker Compose
- ✅ cookiecutter
- ✅ Terraform 1.5.7+
- ✅ AWS CLI 2.31.18+

---

## Terraform vs GitHub Actions

| 항목 | Terraform | GitHub Actions |
|------|----------|---------------|
| **역할** | 인프라 생성/삭제 | 앱 배포 |
| **실행 위치** | 로컬 | GitHub 서버 |
| **실행 빈도** | 최초 1회 + 인프라 변경 시 | 코드 푸시할 때마다 |
| **명령어** | `terraform apply` | `git push` (자동) |
| **생성 대상** | VPC, RDS, ECS 클러스터 등 | Docker 이미지, 배포 |
| **비용** | 리소스 생성 시 | 무료 (GitHub Actions 2000분/월) |

---

## 참고 자료

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Django 5.2 문서](https://docs.djangoproject.com/en/5.2/)
