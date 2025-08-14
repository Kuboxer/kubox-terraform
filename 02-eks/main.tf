# EKS 클러스터 IAM 역할
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-cluster-role"
    Project = var.project_name
  }
}

# EKS 클러스터 IAM 정책 연결
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS 클러스터
resource "aws_eks_cluster" "kubox_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(data.aws_subnets.private_subnets.ids, data.aws_subnets.public_subnets.ids)
    # security_group_ids 제거 - AWS 자동 생성 보안그룹 사용
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # 로그 활성화 (선택사항)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = {
    Name    = var.cluster_name
    Project = var.project_name
  }
}

# EKS 노드 그룹 IAM 역할
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-node-role"
    Project = var.project_name
  }
}

# EKS 노드 그룹 IAM 정책들 연결
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# EKS Managed Node Group
resource "aws_eks_node_group" "kubox_node_group" {
  cluster_name    = aws_eks_cluster.kubox_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.private_subnets.ids

  # 인스턴스 설정
  instance_types = ["t3.large"]
  capacity_type  = "SPOT"  # 비용 절약을 위해 스팟 인스턴스 사용
  
  # 스케일링 설정 (고정 2개)
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  # 업데이트 설정
  update_config {
    max_unavailable = 1
  }

  # 디스크 설정
  disk_size = var.node_disk_size

  # SSH 접근을 위한 키 설정
  remote_access {
    ec2_ssh_key = "kubox"
  }

  # 의존성 설정
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = {
    Name    = "${var.cluster_name}-node-group"
    Project = var.project_name
  }
}