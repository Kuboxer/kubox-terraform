# Provider 설정
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"      # AWS 공식 프로바이더 사용
      version = "~> 5.0"             # 버전 5.x 사용 (5.1, 5.2 등 가능)
    }
  }
}

provider "aws" {
  region = "us-east-2"  # 오하이오 리전에서 작업
}