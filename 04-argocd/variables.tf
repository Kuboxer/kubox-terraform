# 기본 변수
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "kubox"
}

# ArgoCD 관련 변수
variable "argocd_host" {
  description = "ArgoCD hostname"
  type        = string
  default     = "argocd.kubox.shop"
}

variable "argocd_namespace" {
  description = "ArgoCD namespace"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "create_route53_record" {
  description = "Create Route53 record for ArgoCD"
  type        = bool
  default     = true
}

variable "cert_validity_hours" {
  description = "Self-signed certificate validity in hours"
  type        = number
  default     = 8760  # 1년
}

# GitHub OAuth 설정
variable "github_client_id" {
  description = "GitHub OAuth App Client ID"
  type        = string
  default     = ""
}

variable "github_client_secret" {
  description = "GitHub OAuth App Client Secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_org" {
  description = "GitHub Organization name for access control"
  type        = string
  default     = ""
}

variable "enable_github_oauth" {
  description = "Enable GitHub OAuth integration"
  type        = bool
  default     = false
}
