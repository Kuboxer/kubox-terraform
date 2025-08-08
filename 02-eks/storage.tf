# ===========================================
# StorageClass 설정 (PVC -> PV 자동 생성)
# ===========================================

# 기본 StorageClass (강사님 자료 기준)
resource "kubernetes_storage_class" "standard" {
  metadata {
    name = "standard"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Delete"

  parameters = {
    type = "gp3"
  }

  depends_on = [
    aws_eks_addon.ebs_csi_driver
  ]
}
