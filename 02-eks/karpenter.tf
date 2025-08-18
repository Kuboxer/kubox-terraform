# ===========================================
# Karpenter 설치 및 설정 (수동 설치 방법 기반)
# ===========================================

# EC2 Spot fleet service-linked role 확인 (자동 생성되므로 생략 가능)

# Karpenter Node IAM Role
resource "aws_iam_role" "karpenter_node" {
  name = "KarpenterNodeRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "KarpenterNodeRole-${var.cluster_name}"
    Project = var.project_name
  }
}

# Karpenter Node IAM Policies
resource "aws_iam_role_policy_attachment" "karpenter_node_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", 
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role       = aws_iam_role.karpenter_node.name
  policy_arn = each.value
}

# Karpenter Node Instance Profile
resource "aws_iam_instance_profile" "karpenter_node" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node.name

  tags = {
    Name    = "KarpenterNodeInstanceProfile-${var.cluster_name}"
    Project = var.project_name
  }
}

# Karpenter Controller IAM Role
resource "aws_iam_role" "karpenter_controller" {
  name = "KarpenterControllerRole-${var.cluster_name}"

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
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:karpenter"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "KarpenterControllerRole-${var.cluster_name}"
    Project = var.project_name
  }
}

# Karpenter용 SQS Queue (Interruption Handling)
resource "aws_sqs_queue" "karpenter" {
  name                      = "${var.cluster_name}-karpenter"
  message_retention_seconds = 300

  tags = {
    Name    = "${var.cluster_name}-karpenter"
    Project = var.project_name
  }
}

# SQS Queue 정책
resource "aws_sqs_queue_policy" "karpenter" {
  queue_url = aws_sqs_queue.karpenter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter.arn
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.karpenter_controller.arn
        }
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.karpenter.arn
      }
    ]
  })
}

# EventBridge Rules for Spot Instance Interruption
resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  name = "${var.cluster_name}-karpenter-spot-interruption"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = {
    Name    = "${var.cluster_name}-karpenter-spot-interruption"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  rule      = aws_cloudwatch_event_rule.karpenter_spot_interruption.name
  target_id = "KarpenterSpotInterruptionTarget"
  arn       = aws_sqs_queue.karpenter.arn
}

# Scheduled Change Events
resource "aws_cloudwatch_event_rule" "karpenter_scheduled_change" {
  name = "${var.cluster_name}-karpenter-scheduled-change"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })

  tags = {
    Name    = "${var.cluster_name}-karpenter-scheduled-change"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "karpenter_scheduled_change" {
  rule      = aws_cloudwatch_event_rule.karpenter_scheduled_change.name
  target_id = "KarpenterScheduledChangeTarget"
  arn       = aws_sqs_queue.karpenter.arn
}

# Instance Rebalance Recommendation
resource "aws_cloudwatch_event_rule" "karpenter_rebalance" {
  name = "${var.cluster_name}-karpenter-rebalance"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = {
    Name    = "${var.cluster_name}-karpenter-rebalance"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "karpenter_rebalance" {
  rule      = aws_cloudwatch_event_rule.karpenter_rebalance.name
  target_id = "KarpenterRebalanceTarget"
  arn       = aws_sqs_queue.karpenter.arn
}
resource "aws_iam_policy" "karpenter_controller" {
  name = "KarpenterControllerPolicy-${var.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Karpenter"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Sid    = "KarpenterSQS"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.karpenter.arn
      },
      {
        Sid    = "ConditionalEC2Termination"
        Effect = "Allow"
        Action = "ec2:TerminateInstances"
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid      = "PassNodeIAMRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.karpenter_node.arn
      },
      {
        Sid      = "EKSClusterEndpointLookup"
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = aws_eks_cluster.kubox_cluster.arn
      },
      {
        Sid    = "AllowScopedInstanceProfileCreationActions"
        Effect = "Allow"
        Action = ["iam:CreateInstanceProfile"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"            = var.region
          }
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileTagActions"
        Effect = "Allow"
        Action = ["iam:TagInstanceProfile"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"            = var.region
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"  = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"             = var.region
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileActions"
        Effect = "Allow"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"            = var.region
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Action   = "iam:GetInstanceProfile"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "KarpenterControllerPolicy-${var.cluster_name}"
    Project = var.project_name
  }
}

# Karpenter Controller Policy 연결
resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

# Karpenter ServiceAccount
resource "kubernetes_service_account" "karpenter" {
  metadata {
    name      = "karpenter"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
    }
  }

  depends_on = [aws_iam_role.karpenter_controller]
}

# Helm Registry 로그인 및 Karpenter CRDs 설치
resource "null_resource" "helm_registry_login" {
  depends_on = [aws_eks_cluster.kubox_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      # Helm Registry 로그아웃 후 로그인
      helm registry logout public.ecr.aws || true
      helm registry login -u AWS -p $(aws ecr-public get-login-password --region us-east-1) public.ecr.aws
      
      # EKS 클러스터 연결 설정
      aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}
      
      # Karpenter CRDs 설치 (v1.6.0)
      kubectl create -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/v1.6.0/pkg/apis/crds/karpenter.sh_nodepools.yaml --dry-run=client -o yaml | kubectl apply -f -
      kubectl create -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/v1.6.0/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml --dry-run=client -o yaml | kubectl apply -f -
      kubectl create -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/v1.6.0/pkg/apis/crds/karpenter.sh_nodeclaims.yaml --dry-run=client -o yaml | kubectl apply -f -
    EOT
  }

  triggers = {
    cluster_name = var.cluster_name
    karpenter_version = "1.6.0"
  }
}

# AMI ID 조회
data "aws_ssm_parameter" "eks_ami_al2023" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

# Karpenter Helm Chart
resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.6.0"
  namespace  = "kube-system"
  
  timeout = 900
  wait    = true

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.kubox_cluster.name
  }

  set {
    name  = "settings.interruptionQueue"
    value = aws_sqs_queue.karpenter.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.karpenter.metadata[0].name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"  # 1에서 100m로 줄이기
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "256Mi"  # 1Gi에서 256Mi로 줄이기
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "500m"  # 1에서 500m로 줄이기
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "512Mi"  # 1Gi에서 512Mi로 줄이기
  }

  set {
    name  = "dnsPolicy"
    value = "Default"
  }

  # Node Affinity 설정 (MNG 노드에서만 실행)
  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "karpenter.sh/nodepool"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "DoesNotExist"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key"
    value = "eks.amazonaws.com/nodegroup"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].operator"
    value = "In"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].values[0]"
    value = aws_eks_node_group.kubox_node_group.node_group_name
  }

  depends_on = [
    null_resource.helm_registry_login,
    kubernetes_service_account.karpenter,
    aws_iam_role_policy_attachment.karpenter_controller,
    kubernetes_config_map.aws_auth
  ]
}
