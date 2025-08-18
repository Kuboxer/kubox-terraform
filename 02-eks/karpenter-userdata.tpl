#!/bin/bash

# EKS 부트스트랩 스크립트
/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${ca_data} \
  --apiserver-endpoint ${endpoint} \
  --container-runtime containerd \
  --kubelet-extra-args '--node-labels=provisioner=karpenter'

# Docker 설정 (필요시)
systemctl enable docker
systemctl start docker

# CloudWatch 에이전트 설치 (옵션)
yum install -y amazon-cloudwatch-agent

# SSM 에이전트 확인
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
