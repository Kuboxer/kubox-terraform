# ===========================================
# StorageClass 설정 (PVC -> PV 자동 생성)
# ===========================================

# 기본 gp3 StorageClass (암호화 + 고성능)
resource "kubernetes_storage_class" "kubox_gp3" {
  metadata {
    name = "kubox-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
    iops      = "3000"    # gp3 기본 IOPS
    throughput = "125"    # gp3 기본 처리량 (MiB/s)
    "csi.storage.k8s.io/fstype" = "ext4"
  }
}

# 고성능 StorageClass (데이터베이스용)
resource "kubernetes_storage_class" "kubox_gp3_high_performance" {
  metadata {
    name = "kubox-gp3-high-perf"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Retain"  # 데이터 보호를 위해 Retain

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
    iops      = "10000"   # 고성능
    throughput = "500"    # 고성능
    "csi.storage.k8s.io/fstype" = "ext4"
  }
}

# io2 StorageClass (초고성능 + 높은 내구성)
resource "kubernetes_storage_class" "kubox_io2" {
  metadata {
    name = "kubox-io2-ultra"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Retain"

  parameters = {
    type      = "io2"
    encrypted = "true"
    fsType    = "ext4"
    iops      = "20000"   # 초고성능
    "csi.storage.k8s.io/fstype" = "ext4"
  }
}
