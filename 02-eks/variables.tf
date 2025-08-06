# 프로젝트 기본 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "kubox"
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "us-east-2"
}

# EKS 클러스터 설정
variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "kubox-cluster"
}

variable "cluster_version" {
  description = "EKS 클러스터 Kubernetes 버전"
  type        = string
  default     = "1.31"
}

# EKS 노드 그룹 설정
variable "node_group_name" {
  description = "EKS 노드 그룹 이름"
  type        = string
  default     = "kubox_node_group"
}

variable "node_instance_types" {
  description = "워커 노드 인스턴스 타입 (스팟 인스턴스용 여러 타입)"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_capacity_type" {
  description = "노드 용량 타입 (ON_DEMAND 또는 SPOT)"
  type        = string
  default     = "SPOT"
}

variable "node_desired_size" {
  description = "원하는 노드 수"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "최대 노드 수"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "최소 노드 수"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "노드 디스크 크기 (GB)"
  type        = number
  default     = 20
}
