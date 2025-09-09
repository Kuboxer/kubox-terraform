variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "kubox-cluster"
}

variable "sonarqube_version" {
  description = "SonarQube chart version"
  type        = string
  default     = "10.2.0"
}

variable "sonarqube_image_tag" {
  description = "SonarQube image tag"
  type        = string
  default     = "10.2.1-community"
}

variable "storage_size" {
  description = "Storage size for SonarQube data"
  type        = string
  default     = "10Gi"
}

variable "postgresql_storage_size" {
  description = "Storage size for PostgreSQL"
  type        = string
  default     = "8Gi"
}

variable "memory_limit" {
  description = "Memory limit for SonarQube"
  type        = string
  default     = "4Gi"
}

variable "cpu_limit" {
  description = "CPU limit for SonarQube"
  type        = string
  default     = "1000m"
}
