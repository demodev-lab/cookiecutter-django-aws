# Django AWS Cookiecutter Template - 진행상황

**마지막 업데이트:** 2025-10-17 (회사 Mac에서 작업 완료, 집 Windows WSL에서 이어서 작업 예정)

## 프로젝트 개요
Django 5.2.7 + AWS 배포를 위한 cookiecutter 템플릿 제작 중

**핵심 기능:**
- Django REST Framework + JWT 인증
- AWS S3 presigned URL 방식으로 모든 파일 처리 (static, media)
- Docker Compose로 로컬 개발 환경 구성
- PostgreSQL, Redis, Celery, WebSocket(Channels) 지원
- uv 패키지 매니저 사용
- ECS-EC2 배포 타겟

## 완료된 작업 ✅

### 1. S3 설정 단순화
**파일:** `{{cookiecutter.project_slug}}/backend/config/settings.py` (Lines 137-158)

**핵심 변경:**
- DEBUG 모드 체크 제거 - 로컬에서도 S3 사용
- USE_S3 플래그 제거
- Django 자동 파일 저장 기능 제거 (FileSystemStorage, S3Boto3Storage 사용 안함)
- **전략:** 모든 파일을 presigned URL로만 처리, 클라이언트가 직접 S3에 업로드

**최종 설정:**
```python
# AWS S3 Configuration - Always enabled for all environments
AWS_ACCESS_KEY_ID = env('AWS_ACCESS_KEY_ID')  # Required
AWS_SECRET_ACCESS_KEY = env('AWS_SECRET_ACCESS_KEY')  # Required
AWS_STORAGE_BUCKET_NAME = env('AWS_STORAGE_BUCKET_NAME', default='...')
AWS_S3_REGION_NAME = '{{cookiecutter.aws_region}}'
AWS_PRESIGNED_URL_EXPIRY = 3600  # 1 hour
```

### 2. .env 파일 위치 변경
**변경:** `backend/.env.example` → `.env.example` (프로젝트 루트)

**이유:** docker-compose.yml이 루트에 있어서 env_file 설정을 위해 필요

**docker-compose.yml 변경:**
- 모든 서비스에 `env_file: - .env` 추가
- 하드코딩된 환경변수들 제거

### 3. pyproject.toml 빌드 설정 제거
**파일:** `{{cookiecutter.project_slug}}/backend/pyproject.toml`

**문제:** `[build-system]` 섹션 때문에 uv가 Django 앱을 Python 패키지로 빌드 시도 → 실패

**해결:** `[build-system]` 섹션 전체 삭제 (Django 앱은 패키지 빌드 불필요)

### 4. Jinja2 템플릿 공백 문제 수정
**파일:** `{{cookiecutter.project_slug}}/docker-compose.yml`

**문제:** `{% if ... -%}` 의 `-` 때문에 필요한 공백 제거 → YAML 들여쓰기 깨짐

**해결:** 모든 `-%}` → `%}`로 변경

### 5. docker-compose.yml 최신화
- `version: '3.8'` 제거 (obsolete warning 방지)

### 6. README.md 완전히 업데이트
**파일:** `{{cookiecutter.project_slug}}/README.md`

**업데이트 내용:**
- AWS 자격증명 필수 요구사항 명시
- `docker-compose` → `docker compose` 명령어 수정 (Docker Compose V2)
- Django 명령어에 `uv run` 접두사 추가
- S3 Presigned URL 아키텍처 설명 추가
- Python 코드 예제 추가 (presigned URL 생성 API 샘플)

### 7. .gitignore 파일 생성
**템플릿 루트 및 생성될 프로젝트 양쪽 모두:**
- `test-output/` - cookiecutter 테스트용
- `.env` - AWS 자격증명 포함
- `uv.lock` - 머신마다 다름
- Python, IDE 관련 파일들

### 8. 테스트 완료
**테스트 환경:** macOS (회사)

**명령어:**
```bash
cookiecutter . --output-dir test-output --overwrite-if-exists
cd test-output/my_django_project
docker compose up -d --build
```

**결과:**
- ✅ 6개 컨테이너 모두 정상 실행
  - PostgreSQL 15
  - Redis 7
  - Backend (Django + DRF)
  - WebSocket (Daphne)
  - Celery Worker
  - Celery Beat
- ✅ uv sync 성공 (64개 패키지 설치)
- ✅ 실제 AWS 자격증명으로 테스트 완료

## 현재 상태 (커밋 직전)

### 완성된 것 ✅
1. **Cookiecutter 템플릿 기본 구조** - 완전히 작동함
2. **S3 Presigned URL 전략** - 설정 및 문서화 완료
3. **Docker Compose 로컬 환경** - 6개 서비스 정상 작동
4. **문서화** - README.md 완전히 업데이트
5. **테스트** - macOS에서 전체 플로우 검증 완료

### 아직 구현 안된 것 (선택사항)
1. **S3 Presigned URL API 실제 구현**
   - README에 예제 코드만 있음
   - 실제 Django 앱 없음 (필요시 `apps/common/` 생성)

2. **Terraform 인프라 코드** (cookiecutter.json에 use_terraform 옵션 있음)
   - S3 버킷
   - IAM 역할/정책
   - ECS 클러스터

3. **GitHub Actions CI/CD** (cookiecutter.json에 ci_cd_platform 옵션 있음)
   - 자동 테스트
   - ECS 배포

4. **테스트 코드**
   - pytest 설정은 있지만 실제 테스트 파일 없음

## 집에서 작업 시작할 때 (Windows WSL)

### 1. 환경 준비

```bash
# Git clone (집 PC)
cd ~/projects  # 또는 원하는 디렉토리
git clone <your-repo-url> cookiecutter-django-aws
cd cookiecutter-django-aws

# 브랜치 확인
git branch
git log --oneline -5
```

### 2. .env 파일 생성 (필수!)
**집에서 다시 만들어야 함 (.gitignore에 포함되어 있어서 push 안됨)**

프로젝트 루트에 `.env` 파일 생성:
```bash
# Database
POSTGRES_DB=your_db_name
POSTGRES_USER=your_db_user
POSTGRES_PASSWORD=your_secure_password
DATABASE_URL=postgresql://your_db_user:your_secure_password@db:5432/your_db_name

# Django
SECRET_KEY=your-super-secret-key-here-change-this-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# AWS S3 (Required - 여기에 실제 AWS 키 입력!)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_STORAGE_BUCKET_NAME=your-bucket-name

# Redis
REDIS_URL=redis://redis:6379/0

# Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
```

### 3. Windows WSL 환경 차이점

**Docker 명령어 동일:**
```bash
# WSL에서도 동일하게 작동
docker compose up -d --build
docker compose logs -f backend
docker compose exec backend uv run python manage.py migrate
```

**경로 차이:**
- macOS: `/Users/surokim/...`
- WSL: `/home/<username>/...` 또는 `/mnt/c/Users/...`

**파일 권한:**
WSL에서 Windows 파일시스템(`/mnt/c`) 사용 시 권한 문제 발생 가능
→ WSL 네이티브 경로(`/home/<username>`) 사용 권장

### 4. 테스트 명령어 (WSL에서)

```bash
# 1. 템플릿으로 프로젝트 생성
cookiecutter . --output-dir test-output --overwrite-if-exists

# 입력 예시:
# project_name: My Django Project
# project_slug: my_django_project
# author_name: Your Name
# aws_region: ap-northeast-2
# use_celery: yes
# use_websocket: yes
# use_terraform: no
# ci_cd_platform: github

# 2. .env 파일 복사
cp .env test-output/my_django_project/.env

# 3. Docker Compose 실행
cd test-output/my_django_project
docker compose up -d --build

# 4. 로그 확인
docker compose logs -f backend

# 5. 마이그레이션
docker compose exec backend uv run python manage.py migrate

# 6. 슈퍼유저 생성
docker compose exec backend uv run python manage.py createsuperuser

# 7. 정리
docker compose down -v
cd ../../
rm -rf test-output
```

## 다음에 할 일 (우선순위 순)

### 필수는 아니지만 유용한 것들:

#### 1. S3 Presigned URL API 구현
**언제 필요한가:** 템플릿을 실제 프로젝트에 사용할 때

```bash
# 생성된 프로젝트에서 실행
cd backend
uv run python manage.py startapp apps/common

# 구현할 것:
# - apps/common/views.py: get_upload_url, get_download_url
# - apps/common/urls.py: URL 라우팅
# - backend/config/urls.py: apps/common 연결
```

**참고:** README.md에 예제 코드 이미 있음

#### 2. Terraform 인프라 코드
**언제 필요한가:** AWS에 실제 배포할 때

```bash
# 템플릿에 추가할 것:
mkdir -p {{cookiecutter.project_slug}}/terraform
# terraform/main.tf: S3, IAM, ECS 리소스
# terraform/variables.tf: 변수 정의
# terraform/outputs.tf: 출력값
```

#### 3. GitHub Actions CI/CD
**언제 필요한가:** 자동 배포 원할 때

```bash
# 템플릿에 추가할 것:
mkdir -p {{cookiecutter.project_slug}}/.github/workflows
# .github/workflows/ci.yml: 테스트 실행
# .github/workflows/deploy.yml: ECS 배포
```

#### 4. 실제 사용 예제 앱
**언제 필요한가:** 템플릿 사용법 보여줄 때

```bash
# 예시: 블로그 앱 (S3 이미지 업로드 포함)
# - apps/blog/ 앱 생성
# - Post 모델 (title, content, image_url)
# - S3 presigned URL로 이미지 업로드 API
```

## 파일 구조 (핵심 파일만)

```
cookiecutter-django-aws/
├── .gitignore                           # .env, test-output/ 제외
├── PROGRESS.md                          # 이 파일
├── cookiecutter.json                    # 템플릿 변수 정의
└── {{cookiecutter.project_slug}}/
    ├── .env.example                     # 환경변수 템플릿 (루트!)
    ├── .gitignore                       # 생성될 프로젝트용
    ├── docker-compose.yml               # 6개 서비스 정의
    ├── README.md                        # 완전히 업데이트됨
    └── backend/
        ├── config/
        │   ├── settings.py              # S3 설정 (137-158라인)
        │   └── urls.py
        ├── pyproject.toml               # [build-system] 제거됨
        ├── Dockerfile
        └── manage.py
```

## 중요한 개념 정리

### S3 Presigned URL 전략
**기존 방식 (사용 안함):**
- Django FileField로 파일 업로드
- django-storages가 자동으로 S3에 저장
- Django 서버가 파일을 중계

**현재 방식 (채택):**
1. 클라이언트: "파일 업로드할게요" → Django API
2. Django: Presigned URL 생성 → 클라이언트
3. 클라이언트: 파일 직접 S3에 업로드 (PUT request)
4. 클라이언트: S3 키(파일경로)를 Django API에 전송
5. Django: S3 키를 DB에 저장 (CharField)

**장점:**
- Django 서버 부하 없음
- 빠른 업로드
- 로컬 개발 환경도 동일한 방식

### uv 패키지 매니저
```bash
# 의존성 추가
uv add django-extensions

# 의존성 제거
uv remove django-extensions

# 동기화 (pip install과 유사)
uv sync

# 명령어 실행
uv run python manage.py migrate
uv run pytest
```

**주의:** `uv.lock` 파일은 gitignore (머신마다 다를 수 있음)

### Docker Compose V2
- ❌ `docker-compose` (구버전)
- ✅ `docker compose` (새 버전, 하이픈 없음)

WSL에서도 `docker compose` 사용

## 트러블슈팅

### 문제 1: uv sync 실패
**원인:** `[build-system]`이 pyproject.toml에 있음
**해결:** 이미 제거됨, 더 이상 발생 안함

### 문제 2: docker-compose.yml 들여쓰기 깨짐
**원인:** Jinja2 `-%}` 공백 제거
**해결:** 이미 수정됨

### 문제 3: .env 파일을 찾을 수 없음
**확인 사항:**
1. .env 파일이 프로젝트 루트에 있는지 (backend/ 안 아님!)
2. docker-compose.yml과 같은 레벨

### 문제 4: AWS 자격증명 오류
**확인 사항:**
1. .env에 실제 AWS 키 입력했는지
2. S3 버킷이 실제로 존재하는지
3. IAM 권한에 S3 접근 권한 있는지

## 커밋 메시지 (참고용)

```
Initial cookiecutter Django AWS template

- Django 5.2.7 + Python 3.12 + uv package manager
- S3 presigned URL strategy for all file operations
- Docker Compose setup with PostgreSQL, Redis, Celery, WebSocket
- Fully tested on macOS, ready for deployment
- Comprehensive documentation with examples
```

## 마지막 체크리스트

출근해서 다시 시작할 때:
- [ ] `git pull origin main` - 최신 코드 받기
- [ ] `.env` 파일 생성 (AWS 자격증명 입력)
- [ ] `PROGRESS.md` 이 파일 다시 읽기
- [ ] 다음 작업 선택 (S3 API? Terraform? GitHub Actions?)

---

**작업 환경:**
- 회사: macOS (완료)
- 집: Windows 11 + WSL2 (예정)

**Git 저장소:** 커밋 → 푸쉬 완료 후 집에서 클론
