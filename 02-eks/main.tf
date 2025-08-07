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

# EKS 워커 노드 1
resource "aws_instance" "worker_node_1" {
  ami           = data.aws_ssm_parameter.eks_ami.value
  instance_type = "t3.micro"
  key_name      = "kubox"
  
  # 스팟 인스턴스 설정
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.0104"
    }
  }
  
  subnet_id              = data.aws_subnets.private_subnets.ids[0]
  vpc_security_group_ids = [aws_eks_cluster.kubox_cluster.vpc_config[0].cluster_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.eks_node_instance_profile.name
  
  # EKS 부트스트랩 스크립트
  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    cluster_name = aws_eks_cluster.kubox_cluster.name
    endpoint     = aws_eks_cluster.kubox_cluster.endpoint
    ca_data      = aws_eks_cluster.kubox_cluster.certificate_authority[0].data
  }))

  tags = {
    Name    = "kubox-worker-1"
    Project = var.project_name
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# EKS 워커 노드 2
resource "aws_instance" "worker_node_2" {
  ami           = data.aws_ssm_parameter.eks_ami.value
  instance_type = "t3.micro"
  key_name      = "kubox"
  
  # 스팟 인스턴스 설정
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.0104"
    }
  }
  
  subnet_id              = data.aws_subnets.private_subnets.ids[1]
  vpc_security_group_ids = [aws_eks_cluster.kubox_cluster.vpc_config[0].cluster_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.eks_node_instance_profile.name
  
  # EKS 부트스트랩 스크립트
  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    cluster_name = aws_eks_cluster.kubox_cluster.name
    endpoint     = aws_eks_cluster.kubox_cluster.endpoint
    ca_data      = aws_eks_cluster.kubox_cluster.certificate_authority[0].data
  }))

  tags = {
    Name    = "kubox-worker-2"
    Project = var.project_name
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# IAM Instance Profile for worker nodes
resource "aws_iam_instance_profile" "eks_node_instance_profile" {
  name = "${var.cluster_name}-node-instance-profile"
  role = aws_iam_role.eks_node_role.name
}

# EKS 최적화 AMI 정보 가져오기
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.kubox_cluster.version}/amazon-linux-2/recommended/image_id"
}

# AWS Load Balancer Controller를 위한 IAM 정책
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name = "${var.cluster_name}-aws-load-balancer-controller"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-aws-load-balancer-controller"
    Project = var.project_name
  }
}

# ===========================================
# EBS CSI Driver를 위한 IAM 역할 및 IRSA
# ===========================================

# EBS CSI Driver를 위한 IAM 정책
resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name = "${var.cluster_name}-ebs-csi-driver-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteSnapshot",
          "ec2:DeleteTags",
          "ec2:DeleteVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DetachVolume",
          "ec2:ModifyVolume"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${var.cluster_name}-ebs-csi-driver-policy"
    Project = var.project_name
  }
}

# EBS CSI Driver를 위한 IAM 역할 (IRSA 용)
resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "${var.cluster_name}-ebs-csi-driver-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = {
    Name    = "${var.cluster_name}-ebs-csi-driver-role"
    Project = var.project_name
  }
}

# EBS CSI Driver 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = aws_iam_policy.ebs_csi_driver_policy.arn
}

# EKS 애드온: EBS CSI Driver
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name         = aws_eks_cluster.kubox_cluster.name
  addon_name          = "aws-ebs-csi-driver"
  addon_version       = "v1.32.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn
  
  depends_on = [
    aws_instance.worker_node_1,
    aws_instance.worker_node_2,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy_attachment
  ]
  
  tags = {
    Name    = "${var.cluster_name}-ebs-csi-driver"
    Project = var.project_name
  }
}


