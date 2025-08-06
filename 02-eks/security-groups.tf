# EKS 추가 보안그룹 (특별한 요구사항이 있을 때만 사용)
# 현재는 AWS 기본 보안그룹만 사용하므로 비활성화

# resource "aws_security_group" "eks_additional_sg" {
#   name        = "kubox-eks-additional-sg"
#   description = "Additional security group for EKS cluster if needed"
#   vpc_id      = data.aws_vpc.kubox_vpc.id
# 
#   # 특별한 추가 규칙이 필요한 경우에만 활성화
#   
#   tags = {
#     Name    = "kubox-eks-additional-sg"
#     Project = var.project_name
#   }
# }

# 참고: EKS는 자동으로 다음 보안그룹을 생성합니다:
# - eks-cluster-sg-{cluster-name}-{random-id}: 클러스터 컨트롤 플레인용
# - 이 보안그룹에는 워커노드와 컨트롤플레인 간 모든 필요한 통신 규칙이 포함됩니다
