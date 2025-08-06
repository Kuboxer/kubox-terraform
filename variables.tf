# AWS 리전 설정
variable "region" {
  description = "AWS 리전 (조 계정 확정되면 수정될 수 있음)"
  type        = string
  default     = "us-east-2"
}

# 프로젝트 이름
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "kubox"
}

# VPC CIDR 블록
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

# 가용영역 (비용 최적화를 위해 2개 사용)
variable "azs" {
  description = "사용할 가용영역 목록 (3개는 안정성이 높지만 비용 증가로 2개 사용)"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2c"]
}

# 서브넷 CIDR 설정
variable "subnet_cidrs" {
  description = "서브넷별 CIDR 블록 설정"
  type = object({
    public = object({
      a = string  # public-subnet-a (NAT Gateway용)
      c = string  # public-subnet-c
    })
    private = object({
      a = string  # private-subnet-a (EKS Cluster용)
      c = string  # private-subnet-c (EKS Cluster용)
    })
    rds = object({
      a = string  # rds-subnet-a (RDS Primary)
      c = string  # rds-subnet-c (RDS Secondary)
    })
    elasticache = object({
      a = string  # elasticache-subnet-a
      c = string  # elasticache-subnet-c
    })
  })
  default = {
    public = {
      a = "10.0.1.0/24"   # NAT Gateway용
      c = "10.0.2.0/24"
    }
    private = {
      a = "10.0.11.0/24"  # user, login, product
      c = "10.0.12.0/24"  # order, payment
    }
    rds = {
      a = "10.0.21.0/24"  # RDS Primary
      c = "10.0.22.0/24"  # RDS Secondary
    }
    elasticache = {
      a = "10.0.31.0/24"
      c = "10.0.32.0/24"
    }
  }
}

# 환경 설정
variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# 태그 설정
variable "common_tags" {
  description = "모든 리소스에 적용될 공통 태그"
  type        = map(string)
  default = {
    Project     = "kubox"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
