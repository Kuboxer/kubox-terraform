# 프로젝트 기본 설정
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "kubox"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

# EKS 클러스터 설정
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "kubox-cluster"
}

variable "cluster_version" {
  description = "EKS cluster Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  type        = number
  default     = 30
}
