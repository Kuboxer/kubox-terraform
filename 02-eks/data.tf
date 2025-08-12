# 기존에 만든 VPC 정보 가져오기
data "aws_vpc" "kubox_vpc" {
  filter {
    name   = "tag:Name"
    values = ["kubox-vpc"]
  }
}

# Private 서브넷들 가져오기 (EKS 워커 노드용)
data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.kubox_vpc.id]
  }
  
  filter {
    name   = "tag:Description"
    values = ["EKS worker nodes subnet"]
  }
}

# Public 서브넷들 가져오기 (로드밸런서용)
data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.kubox_vpc.id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["public-subnet-a", "public-subnet-c"]
  }
}

# EKS 클러스터 인증 정보
data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.kubox_cluster.name
}
