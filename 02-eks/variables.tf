# 프로젝트 기본 설정
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "kubox"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
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
  default     = "1.31"
}

# EKS 노드 그룹 설정
variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "kubox-node-group"
}

variable "node_instance_types" {
  description = "Worker node instance types (multiple types for spot instances)"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_capacity_type" {
  description = "Node capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "SPOT"
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  type        = number
  default     = 20
}
