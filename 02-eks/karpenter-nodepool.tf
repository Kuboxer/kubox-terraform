# ===========================================
# Karpenter NodePool 및 EC2NodeClass 설정
# ===========================================

# Karpenter NodePool 및 EC2NodeClass 생성
resource "null_resource" "karpenter_nodepool" {
  depends_on = [
    helm_release.karpenter,
    aws_ec2_tag.private_subnet_karpenter,
    aws_ec2_tag.cluster_sg_karpenter,
    null_resource.helm_registry_login
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # EKS 클러스터 연결 설정
      aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}
      
      # Karpenter가 준비될 때까지 대기
      echo "Waiting for Karpenter to be ready..."
      kubectl wait --for=condition=Available deployment/karpenter -n kube-system --timeout=600s
      
      # ALIAS_VERSION 계산
      ALIAS_VERSION=$(aws ssm get-parameter \
        --name "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id" \
        --query Parameter.Value --output text | \
        xargs aws ec2 describe-images --query 'Images[0].Name' --image-ids | \
        sed -r 's/^.*(v[[:digit:]]+).*$/\1/')
      
      echo "Using ALIAS_VERSION: $ALIAS_VERSION"
      
      # Default EC2NodeClass 생성 (태그 수정)
      kubectl apply -f - <<EOF
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  instanceProfile: "${aws_iam_instance_profile.karpenter_node.name}"
  amiSelectorTerms:
    - alias: "al2023@$ALIAS_VERSION"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${var.cluster_name}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${var.cluster_name}"
  tags:
    Name: "${var.cluster_name}-karpenter-node"
    Project: "${var.project_name}"
    karpenter.sh/cluster: "${var.cluster_name}"
EOF

      # WorkloadNodePool 생성 (t3.large 고정)
      kubectl apply -f - <<EOF
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: workload-nodepool
spec:
  template:
    metadata:
      labels:
        node-type: workload
        provisioner: karpenter
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ["t3.large"]
      expireAfter: 2h
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 5m
EOF

      echo "Karpenter NodeClass and NodePool created successfully!"
    EOT
  }

  triggers = {
    cluster_name = var.cluster_name
    karpenter_version = "1.6.0"
    cluster_version = var.cluster_version
  }
}
