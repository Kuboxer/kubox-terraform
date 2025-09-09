# SonarQube 로드밸런서 URL
output "sonarqube_url" {
  description = "SonarQube LoadBalancer URL"
  value       = "http://LoadBalancer-External-IP:9000"
}

# SonarQube 서비스 정보
output "sonarqube_service" {
  description = "SonarQube service information"
  value = {
    namespace = kubernetes_namespace.sonarqube.metadata[0].name
    service_name = "sonarqube-sonarqube"
    port = 9000
  }
}

# 기본 로그인 정보
output "default_credentials" {
  description = "Default SonarQube login credentials"
  value = {
    username = "admin"
    password = "admin"
    note = "Please change password after first login"
  }
}

# PostgreSQL 접속 정보
output "postgresql_info" {
  description = "PostgreSQL connection information"
  value = {
    host = "sonarqube-postgresql"
    port = 5432
    database = "sonar"
    username = "sonar"
  }
  sensitive = false
}
