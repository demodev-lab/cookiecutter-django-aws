# Terraform State Backend Configuration
# State는 S3 bucket에 저장되어 팀원들과 공유됩니다.
# 버킷: {{cookiecutter.terraform_state_bucket}}
# 경로: {{cookiecutter.project_slug}}/<environment>/terraform.tfstate

terraform {
  backend "s3" {
    bucket = "{{cookiecutter.terraform_state_bucket}}"
    key    = "{{cookiecutter.project_slug}}/demo/terraform.tfstate"
    region = "{{cookiecutter.aws_region}}"
    encrypt = true
  }
}
