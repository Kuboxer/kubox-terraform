# EKS 클러스터 보안그룹
resource "aws_security_group" "eks_cluster_sg" {
  name_prefix = "kubox-eks-cluster-sg-"
  description = "EKS Cluster Security Group"
  vpc_id      = data.aws_vpc.kubox_vpc.id

  # HTTPS 트래픽 (API 서버)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS API access"
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name    = "kubox-eks-cluster-sg"
    Project = var.project_name
    Type    = "EKS-Cluster"
  }
}

# EKS 워커 노드 보안그룹
resource "aws_security_group" "eks_node_sg" {
  name_prefix = "kubox-eks-node-sg-"
  description = "EKS Worker Node Security Group"
  vpc_id      = data.aws_vpc.kubox_vpc.id

  # 노드 간 통신
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
    description = "Allow nodes to communicate with each other"
  }

  # 로드밸런서 트래픽 (HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP traffic from load balancer"
  }

  # 로드밸런서 트래픽 (HTTPS)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS traffic from load balancer"
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name    = "kubox-eks-node-sg"
    Project = var.project_name
    Type    = "EKS-Node"
  }
}

# ===========================================
# 별도 규칙들 (순환 참조 방지)
# ===========================================

# 클러스터 → 노드 통신 규칙
resource "aws_security_group_rule" "cluster_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = aws_security_group.eks_node_sg.id
  description              = "Allow cluster control plane to communicate with nodes"
}

# 노드 → 클러스터 통신 규칙
resource "aws_security_group_rule" "node_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_node_sg.id
  security_group_id        = aws_security_group.eks_cluster_sg.id
  description              = "Allow nodes to communicate with cluster API"
}

# 추가: kubelet API 접근 (10250 포트)
resource "aws_security_group_rule" "cluster_to_node_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = aws_security_group.eks_node_sg.id
  description              = "Allow cluster to access kubelet API"
}
