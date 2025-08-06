# AWS 리전 설정
variable "region" {
  description = "AWS region (can be modified when team account is confirmed)"
  type        = string
  default     = "us-east-2"
}

# 프로젝트 이름
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "kubox"
}

# VPC CIDR 블록
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# 가용영역 (비용 최적화를 위해 2개 사용)
variable "azs" {
  description = "List of availability zones to use (using 2 AZs for cost optimization instead of 3)"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2c"]
}

# 서브넷 CIDR 설정
variable "subnet_cidrs" {
  description = "CIDR block configuration for each subnet"
  type = object({
    public = object({
      a = string  # public-subnet-a (for NAT Gateway)
      c = string  # public-subnet-c
    })
    private = object({
      a = string  # private-subnet-a (for EKS Cluster)
      c = string  # private-subnet-c (for EKS Cluster)
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
      a = "10.0.11.0/24"  # EKS worker nodes
      c = "10.0.12.0/24"  # EKS worker nodes
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
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# 태그 설정
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "kubox"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
