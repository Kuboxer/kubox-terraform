# ArgoCD 접속 정보
output "argocd_url" {
  description = "ArgoCD Web UI URL"
  value       = "https://${var.argocd_host}"
}

output "argocd_initial_admin_password" {
  description = "ArgoCD initial admin password"
  value       = try(data.kubernetes_secret.argocd_initial_admin.data.password != null ? base64decode(data.kubernetes_secret.argocd_initial_admin.data.password) : "패스워드를 수동으로 확인하세요", "패스워드를 수동으로 확인하세요")
  sensitive   = true
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = var.argocd_namespace
}

output "argocd_service_name" {
  description = "ArgoCD server service name"
  value       = "argocd-server"
}

# 인증서 정보
output "argocd_cert_expiry" {
  description = "ArgoCD certificate expiry date"
  value       = timeadd(timestamp(), "${var.cert_validity_hours}h")
}

# Route53 레코드 정보
output "route53_record_created" {
  description = "Whether Route53 record was created"
  value       = var.create_route53_record
}

# CLI 접속 명령어
output "argocd_cli_login" {
  description = "ArgoCD CLI login command"
  value       = "argocd login ${var.argocd_host} --username admin --password '<초기패스워드>' --insecure"
}

# 수동 패스워드 확인 명령어
output "manual_password_command" {
  description = "Manual command to get ArgoCD initial password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

# Gateway 상태 확인 명령어
output "gateway_check_commands" {
  description = "Commands to check Istio Gateway status"
  value = [
    "kubectl -n ${var.argocd_namespace} get gateway argocd-gw",
    "kubectl -n ${var.argocd_namespace} get virtualservice argocd",
    "kubectl -n istio-system get secret argocd-tls"
  ]
}

# GitHub OAuth 설정 정보
output "github_oauth_enabled" {
  description = "Whether GitHub OAuth is enabled"
  value       = var.enable_github_oauth
}

output "github_oauth_redirect_url" {
  description = "GitHub OAuth redirect URL (add this to your GitHub OAuth App)"
  value       = var.enable_github_oauth ? "https://${var.argocd_host}/api/dex/callback" : "GitHub OAuth not enabled"
}

output "github_oauth_setup_instructions" {
  description = "Instructions for setting up GitHub OAuth"
  value = var.enable_github_oauth ? [
    "1. Create GitHub OAuth App at: https://github.com/settings/applications/new",
    "2. Set Authorization callback URL to: https://${var.argocd_host}/api/dex/callback",
    "3. Copy Client ID and Client Secret to terraform.tfvars",
    "4. Set enable_github_oauth = true and apply"
  ] : ["Set enable_github_oauth = true to see setup instructions"]
}
