# Django AWS Cookiecutter Template - 진행상황

**마지막 업데이트:** 2025-10-24

---

## 프로젝트 개요

Django 5.2.7 + AWS ECS 배포를 위한 **프로덕션급 Cookiecutter 템플릿**

**핵심 목표:** 외주 계약자가 클라이언트 데모를 빠르게 AWS에 배포할 수 있는 템플릿

**기술 스택:**
- Django 5.2.7 + Django REST Framework + JWT 인증
- **Next.js 16** (프론트엔드 - TypeScript + Tailwind CSS)
- AWS S3 Presigned URL (파일 업로드/다운로드)
- Docker Compose (로컬 개발)
- PostgreSQL 16, Redis 7, Celery, WebSocket (Channels)
- uv 패키지 매니저
- **ECS Fargate** (프로덕션 배포)
- **Terraform** (인프라 관리)
- **Terraform S3 Backend** (State 관리)
- **GitHub Actions** (CI/CD)
- **ALB 경로 기반 라우팅** (/ → Frontend, /api → Backend)

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
  - `backend.tf` - S3 Backend 설정 (NEW!)
  - `README.md` - Terraform 사용 가이드

- ✅ **Terraform S3 Backend 구현 완료**
  - S3 bucket: `demodev-lab-terraform-states` 생성
  - Versioning 활성화 (State 복구 가능)
  - 암호화 활성화 (AES256)
  - State 경로: `{project_name}/demo/terraform.tfstate`
  - GitHub Actions 간 state 공유 가능
  - **terraform destroy가 제대로 작동** ✅

- ✅ **실제 AWS 배포 테스트 성공**
  - terraform init ✅
  - terraform validate ✅
  - terraform plan ✅ (34개 리소스)
  - terraform apply ✅ (34개 리소스 생성 성공)
  - terraform destroy ✅ (완전 삭제 확인)
  - **S3 backend state 저장 확인** ✅

### Phase 3: GitHub Actions CI/CD (완료)

- ✅ **3개 워크플로우 파일 작성**
  - `create-infra.yml` - Terraform 인프라 생성 (수동 트리거)
  - `deploy.yml` - 앱 배포 (main push 시 자동, 수동도 가능)
  - `destroy.yml` - 인프라 삭제 (수동 트리거, 확인 필요)

- ✅ **Makefile 자동화**
  - `make init` - GitHub 레포 생성 + Secrets 설정 + 브랜치 구조
  - `make setup-secrets` - GitHub Secrets 설정
  - `make dev` - 로컬 개발 환경 실행
  - `make destroy-aws-manual` - 긴급 수동 삭제 (Terraform state 문제 시)

- ✅ **브랜치 전략**
  - `main` 브랜치: AWS demo 환경 자동 배포
  - `dev` 브랜치: 로컬 개발만 (docker-compose)

- ✅ **인프라 체크 로직**
  - deploy.yml에 `check-infrastructure` job 추가
  - ECR 존재 여부 확인 후 배포 진행
  - 인프라 없으면 배포 스킬 + 안내 메시지

- ✅ **환경 네이밍 전략 (demo/prod)**
  - `demo` (기본값): 클라이언트 데모용, 작은 인스턴스, 빠른 생성/삭제
  - `prod`: 프로덕션 환경, 큰 인스턴스, 백업/보호 활성화
  - 모든 Terraform 파일에 반영 완료

- ✅ **리소스 네이밍 규칙**
  - 프로젝트 이름 정규화: `_` → `-` 자동 변환
  - ECS Cluster: `{project}-cluster-{env}`
  - ECS Service: `{project}-service-{env}`
  - IAM Execution Role: `{project}-ecs-execution-role-{env}`
  - IAM Task Role: `{project}-ecs-task-role-{env}`
  - Makefile과 Terraform 네이밍 일치

- ✅ **조직 레포지토리 지원**
  - demodev-lab 조직으로 레포 생성
  - Private repo (self-hosted runner 접근)
  - make init에서 조직 선택 가능

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

**커밋 내역:**
- `e468e7f` - Add Terraform infrastructure code with AWS deployment support
- `91e766a` - Update PROGRESS.md with Terraform and AWS deployment plan
- `4191508` - Add Celery configuration files
- `fb24848` - Initial cookiecutter Django AWS template

---

## 현재 작업 중 🚧

**Phase 4: End-to-End 배포 테스트 및 버그 수정 (완료!)**

### 2025-10-23 작업 내역

**테스트 프로젝트:** `test_workflow_v4` (demodev-lab 조직)

#### 해결한 주요 이슈들:

1. **Docker 플랫폼 호환성 문제** ✅
   - 문제: `exec format error` - ARM64 이미지가 ECS Fargate(x86_64)에서 실행 안 됨
   - 해결: Docker Buildx 사용 + `--platform linux/amd64` 옵션 추가
   - 파일: `deploy.yml`, `Dockerfile`

2. **UV 패키지 매니저 설치 방식 개선** ✅
   - 문제: `COPY --from` 방식의 플랫폼 불일치
   - 해결: `pip install uv`로 변경 (플랫폼 무관)
   - 파일: `Dockerfile`

3. **AWS 자격증명 처리** ✅
   - 문제: ECS에서 `AWS_ACCESS_KEY_ID` 환경 변수 필수로 요구
   - 해결: `env('AWS_ACCESS_KEY_ID', default=None)` - IAM Task Role 사용
   - 파일: `settings.py`

4. **리소스 네이밍 불일치** ✅
   - 문제: `test_workflow_v4` vs `test-workflow-v4`
   - 해결: deploy.yml에서 정규화된 이름 사용
   - 파일: `deploy.yml` - `PROJECT_NAME` 환경 변수 추가

5. **HTTPS 강제 리다이렉트 문제** ✅
   - 문제: demo 환경에서 SSL 인증서 없이 HTTPS 리다이렉트 발생
   - 해결: `ENVIRONMENT` 변수 체크, prod 환경에서만 HTTPS 강제
   - 파일: `settings.py`

6. **Django Admin Static 파일 문제** ✅
   - 문제: CSS/JS 파일이 로드되지 않아 Admin 페이지 깨짐
   - 해결: WhiteNoise 추가 + `collectstatic` 실행
   - 파일: `pyproject.toml`, `settings.py`, `Dockerfile`

7. **S3 버킷 이름 일관성** ✅
   - 문제: `test_workflow_v4-media-prod` (잘못된 기본값)
   - 해결: `test-workflow-v4-media-demo` (정규화 + 환경 일치)
   - 파일: `settings.py`, `.env`

8. **ALB URL 동적 조회** ✅
   - 문제: Health check에서 하드코딩된 URL 사용
   - 해결: AWS CLI로 동적 조회 (`PROJECT_NAME` 기반)
   - 파일: `deploy.yml`

9. **Health Check Job AWS Credentials** ✅
   - 문제: Health check job에서 AWS credentials 없음
   - 해결: `configure-aws-credentials` 액션 추가
   - 파일: `deploy.yml`

#### 최종 테스트 결과:

- ✅ **Terraform 인프라 생성 성공** (34개 리소스)
- ✅ **Docker 이미지 빌드 성공** (linux/amd64)
- ✅ **ECR 푸시 성공**
- ✅ **ECS Fargate 배포 성공**
- ✅ **Django 애플리케이션 정상 실행**
- ✅ **ALB를 통한 HTTP 접속 성공**
- ✅ **Django Admin 페이지 정상 표시** (CSS/JS 로드됨)
- ✅ **IAM Task Role 기반 S3 접근 가능**

**접속 URL:** `http://test-workflow-v4-alb-demo-1824358523.ap-northeast-2.elb.amazonaws.com/admin/`

#### 수정된 파일 목록:

**Cookiecutter 템플릿:**
- `{{cookiecutter.project_slug}}/backend/Dockerfile`
- `{{cookiecutter.project_slug}}/backend/pyproject.toml`
- `{{cookiecutter.project_slug}}/backend/config/settings.py`
- `{{cookiecutter.project_slug}}/.github/workflows/deploy.yml`

**테스트 프로젝트 (test_workflow_v4):**
- `backend/Dockerfile`
- `backend/pyproject.toml`
- `backend/config/settings.py`
- `.github/workflows/deploy.yml`
- `.env`

---

## 현재 작업 중 🚧

**Phase 5: Next.js 프론트엔드 추가 및 Full-Stack 배포 (진행 중)**

### 2025-10-24 작업 내역

**테스트 프로젝트:** `test_workflow_v4` (demodev-lab 조직)

#### 완료된 작업:

1. **Next.js 프론트엔드 추가** ✅
   - Next.js 16 + TypeScript + Tailwind CSS
   - 개발용 Dockerfile (Vite dev server)
   - 프로덕션용 Dockerfile.prod (Standalone build)
   - `next.config.ts`에 standalone output 설정

2. **Django API 경로 표준화** ✅
   - 모든 API 엔드포인트에 `/api` prefix 추가
   - Health check: `/api/health/`
   - Admin: `/api/admin/`
   - 환경변수 없이 하드코딩 (표준 패턴)

3. **Terraform 인프라 업데이트** ✅
   - ECR 리포지토리 분리:
     - `test-workflow-v4-backend-demo`
     - `test-workflow-v4-frontend-demo`
   - ECR `force_delete` 옵션 추가 (이미지 있어도 삭제 가능)
   - ALB 경로 기반 라우팅:
     - `/` → Frontend Target Group (Port 3000)
     - `/api/*` → Backend Target Group (Port 8000)
   - ECS Task Definition 분리:
     - Backend Task (Django + Gunicorn)
     - Frontend Task (Next.js SSR)
   - ECS Service 분리:
     - Backend Service
     - Frontend Service
   - CloudWatch 로그 그룹 분리
   - Target Group 헬스체크 경로:
     - Frontend: `/`
     - Backend: `/api/health/`

4. **GitHub Actions 워크플로우 업데이트** ✅
   - `deploy.yml` 전면 수정:
     - Backend 빌드 job 추가
     - Frontend 빌드 job 추가 (Dockerfile.prod 사용)
     - 병렬 빌드 (build-backend, build-frontend)
     - 순차 배포 (Backend → Frontend)
     - 헬스체크 분리 (Frontend `/`, Backend `/api/health/`)
   - 환경 변수 업데이트:
     - `ECR_BACKEND`, `ECR_FRONTEND`
     - `ECS_BACKEND_SERVICE`, `ECS_FRONTEND_SERVICE`

5. **환경변수 및 URL 전략** ✅
   - 로컬 개발: `NEXT_PUBLIC_API_URL=http://localhost:8000`
   - AWS 배포: `NEXT_PUBLIC_API_URL=` (빈 값 = 상대 경로 `/api`)
   - CORS 불필요 (같은 ALB 오리진)
   - docker-compose.yml 업데이트 (frontend 서비스 추가)

6. **Docker 설정** ✅
   - Frontend Dockerfile (개발용, Hot reload)
   - Frontend Dockerfile.prod (프로덕션용, Multi-stage build)
   - Backend Dockerfile 유지 (이미 완성됨)
   - Platform: linux/amd64 (ECS Fargate 호환)

#### 현재 상태:

- ✅ 로컬 docker-compose 테스트 완료 (Backend 정상 작동)
- 🔄 **AWS 배포 진행 중:**
  - Terraform 인프라 재생성 필요 (ECR 이름 변경으로 인해)
  - Destroy 워크플로우 실행 중 (force_delete 추가로 해결)
  - 다음: Create Infrastructure → Deploy

#### 다음 작업:

- [ ] AWS 인프라 재생성 (Destroy → Create)
- [ ] Frontend + Backend 동시 배포 테스트
- [ ] ALB URL 접속 테스트
- [ ] 경로 라우팅 확인 (/, /api/*)
- [ ] 간단한 API 엔드포인트 작성 및 Frontend 연동 테스트
- [ ] S3 Presigned URL 파일 업로드/다운로드 테스트
- [ ] 성공 후 cookiecutter 템플릿으로 변경사항 이동

#### 수정된 파일 (test_workflow_v4):

**새로 추가:**
- `frontend/` (Next.js 프로젝트 전체)
- `frontend/Dockerfile`
- `frontend/Dockerfile.prod`

**수정:**
- `backend/config/urls.py` (API prefix 추가)
- `docker-compose.yml` (frontend 서비스 추가)
- `terraform/ecr.tf` (Backend/Frontend 분리, force_delete)
- `terraform/alb.tf` (경로 기반 라우팅)
- `terraform/ecs.tf` (Backend/Frontend Task/Service 분리)
- `terraform/outputs.tf` (ECR/Service 이름 업데이트)
- `.github/workflows/deploy.yml` (Frontend 빌드/배포 추가)
- `.env` (DATABASE_URL 수정, NEXT_PUBLIC_API_URL 추가)

---

## 다음 단계

**우선순위 1: Full-Stack 배포 완료**
- [ ] AWS 인프라 재생성 완료
- [ ] Frontend + Backend 배포 테스트
- [ ] API 연동 테스트 페이지 작성
- [ ] S3 파일 업로드 테스트

**우선순위 2: cookiecutter 템플릿 통합**
- [ ] test_workflow_v4 변경사항을 템플릿으로 이동
- [ ] README 업데이트 (Frontend 추가)
- [ ] 새 프로젝트로 전체 플로우 테스트

**우선순위 3: 추가 기능 (선택 사항)**
- [ ] Migration 자동 실행 (entrypoint.sh)
- [ ] Superuser 자동 생성 스크립트
- [ ] CloudWatch 로그 필터 설정
- [ ] EC2 All-in-One 배포 옵션 추가

---

## 다음 작업 계획 📋

### 작업 1: EC2 배포 옵션 추가 (선택 사항)

**배경:**
- ECS Fargate: 24/7 운영 시 비용이 높음 (~$9/task/월)
- EC2 All-in-One: 모든 컨테이너를 하나의 EC2에서 실행 (~$7/월 전체)
- 데모 환경에서 극한의 비용 절감 가능

**계획:**
```json
// cookiecutter.json
{
  "aws_deployment": ["ecs-fargate", "ec2-all-in-one"]
}
```

**필요한 작업:**
- [ ] ec2-all-in-one Terraform 템플릿 작성
- [ ] docker-compose를 EC2에서 실행하는 user-data 스크립트
- [ ] GitHub Actions 워크플로우 수정

**주의사항:**
- Django 코드는 동일하게 유지
- 인프라 설정만 변경
- 프로덕션 전환 시 ECS로 쉽게 전환 가능

---

## 사용 방법

### 1. 프로젝트 생성
```bash
cookiecutter cookiecutter-django-aws/
# project_name 입력 (예: my_django_project)
```

### 2. GitHub 레포 생성 및 초기 배포
```bash
cd my_django_project/
cp .env.example .env
# .env 파일 수정 (AWS 키 입력)

make init
# 1. GitHub 레포 생성
# 2. Secrets 설정
# 3. main/dev 브랜치 생성
# 4. Push
```

### 3. AWS 인프라 생성
GitHub Actions에서:
1. "Create AWS Infrastructure" 워크플로우 실행 (수동)
2. 5-10분 대기 (RDS, Redis 생성 시간)
3. 완료 확인

### 4. 앱 자동 배포
```bash
# 코드 수정 후
git add .
git commit -m "Update feature"
git push origin main
# → GitHub Actions가 자동으로 Docker 빌드 + ECR push + ECS 배포
```

### 5. 로컬 개발
```bash
git checkout dev
make dev
# → docker-compose up -d
# → http://localhost:8000
```

### 6. 인프라 삭제
GitHub Actions에서:
1. "Destroy AWS Infrastructure" 워크플로우 실행
2. 확인 입력: "destroy"
3. 완료 대기

**긴급 수동 삭제:**
```bash
make destroy-aws-manual
# "destroy demo" 타이핑하여 확인
```

---

## 비용 정보

### demo 환경 (월 예상)
- RDS db.t3.micro: ~$15
- ElastiCache cache.t3.micro: ~$12
- ECS Fargate (0.25vCPU, 512MB, 1개): ~$9
- ALB: ~$20
- S3, VPC, CloudWatch: ~$3
- **총 ~$60/월**

### prod 환경 (월 예상)
- RDS db.t3.small: ~$30
- ElastiCache cache.t3.small: ~$24
- ECS Fargate (0.5vCPU, 1GB, 2개): ~$18
- ALB: ~$20
- S3, VPC, CloudWatch: ~$6
- **총 ~$100/월**

### EC2 All-in-One (계획 중)
- EC2 t3.micro: ~$7/월
- **모든 컨테이너 포함 (Django, Celery, Redis, PostgreSQL)**
- 데모용으로 충분한 성능

**개발/테스트:**
- 10분 테스트: ~$0.01 (10원)
- 1시간: ~$0.06 (60원)
- terraform destroy로 즉시 삭제 가능

---

## Terraform State 관리

### S3 Backend 설정

**State 저장소:**
- Bucket: `demodev-lab-terraform-states` (회사 공용)
- 경로: `{project_name}/{environment}/terraform.tfstate`
- 암호화: AES256
- Versioning: 활성화

**장점:**
- GitHub Actions 간 state 공유
- 팀원들과 협업 가능
- terraform destroy 정상 작동
- State 손실 시 복구 가능

**주의사항:**
- State bucket은 `make destroy-aws`로 삭제되지 않음
- 프로젝트 완전 폐기 시 수동 삭제 필요:
  ```bash
  aws s3 rm s3://demodev-lab-terraform-states/{project_name}/ --recursive
  ```

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
- ✅ GitHub CLI (gh)

---

## Terraform vs GitHub Actions

| 항목 | Terraform | GitHub Actions |
|------|----------|---------------|
| **역할** | 인프라 생성/삭제 | 앱 배포 |
| **실행 위치** | GitHub Actions | GitHub Actions |
| **실행 빈도** | 최초 1회 + 인프라 변경 시 | 코드 푸시할 때마다 |
| **트리거** | 수동 (workflow_dispatch) | main push 시 자동 |
| **생성 대상** | VPC, RDS, ECS 클러스터 등 | Docker 이미지, 배포 |
| **State 관리** | S3 Backend | N/A |
| **비용** | 리소스 생성 시 | 무료 (2000분/월) |

---

## 알려진 이슈 및 해결 방법

### 1. Terraform State 문제 ✅ (해결됨)
**증상:** `terraform destroy`가 "0 destroyed" 출력
**원인:** State가 로컬에만 저장되어 GitHub Actions에서 접근 불가
**해결:** S3 Backend 사용 (현재 구현됨)

### 2. 리소스 네이밍 불일치 ✅ (해결됨)
**증상:** Makefile로 삭제 시 리소스를 못 찾음
**원인:** Terraform이 `_` → `-` 변환, Makefile은 그대로 사용
**해결:** Makefile에 `PROJECT_NAME_NORMALIZED` 추가, deploy.yml에 `PROJECT_NAME` 환경 변수 추가

### 3. Push 시 자동 배포되는 문제 ✅ (해결됨)
**증상:** 코드 push할 때마다 AWS 리소스 생성
**원인:** deploy.yml에 인프라 체크 로직 없음
**해결:** `check-infrastructure` job 추가

### 4. ECS Service 삭제 실패 ✅ (해결됨)
**증상:** terraform destroy 시 ECS Service 삭제 타임아웃
**원인:** ECS Service의 desired_count가 계속 변경됨
**해결:** lifecycle 정책 추가
```hcl
lifecycle {
  ignore_changes = [desired_count]
}
```

### 5. Docker 플랫폼 호환성 ✅ (해결됨 - 2025-10-23)
**증상:** `exec format error` - ECS Task가 계속 실패
**원인:** ARM64 이미지가 ECS Fargate(x86_64)에서 실행 안 됨
**해결:** Docker Buildx 사용 + `--platform linux/amd64`

### 6. HTTPS 리다이렉트 문제 ✅ (해결됨 - 2025-10-23)
**증상:** demo 환경에서 HTTPS로 리다이렉트되어 접속 불가
**원인:** `SECURE_SSL_REDIRECT=True`가 모든 환경에 적용됨
**해결:** `ENVIRONMENT` 변수로 prod 환경에서만 HTTPS 강제

### 7. Django Admin Static 파일 문제 ✅ (해결됨 - 2025-10-23)
**증상:** Admin 페이지가 CSS/JS 없이 깨져서 표시됨
**원인:** Static 파일 서빙 설정 없음
**해결:** WhiteNoise 추가 + Dockerfile에서 `collectstatic` 실행

---

## 참고 자료

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [AWS ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Django 5.2 문서](https://docs.djangoproject.com/en/5.2/)
