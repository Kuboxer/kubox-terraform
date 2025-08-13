# ===========================================
# Istio 서비스 메시 설치
# ===========================================

# Istio Base 설치 (CRDs 및 기본 구성요소)
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  version          = "1.19.3"

  depends_on = [
    aws_eks_cluster.kubox_cluster,
    aws_instance.worker_node_1,
    aws_instance.worker_node_2
  ]
}

# Istio Discovery (istiod) 설치
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  version    = "1.19.3"

  set {
    name  = "global.meshID"
    value = "mesh1"
  }

  set {
    name  = "global.multiCluster.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "global.network"
    value = "network1"
  }

  depends_on = [
    helm_release.istio_base,
    helm_release.aws_load_balancer_controller
  ]
}

# Istio Ingress Gateway 설치
resource "helm_release" "istio_ingressgateway" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"
  version    = "1.19.3"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  depends_on = [
    helm_release.istiod,
    helm_release.aws_load_balancer_controller
  ]
}

# Default 네임스페이스에 Istio 사이드카 주입 활성화 (Annotation로 처리)
resource "kubernetes_annotations" "default_istio_injection" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "default"
  }
  annotations = {
    "istio-injection" = "enabled"
  }

  depends_on = [helm_release.istiod]
}

# MSA 네임스페이스들 생성 및 Istio 주입 활성화
resource "kubernetes_namespace" "user_ns" {
  metadata {
    name = "user-ns"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [helm_release.istiod]
}

resource "kubernetes_namespace" "product_ns" {
  metadata {
    name = "product-ns"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [helm_release.istiod]
}

resource "kubernetes_namespace" "order_ns" {
  metadata {
    name = "order-ns"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [helm_release.istiod]
}

resource "kubernetes_namespace" "payment_ns" {
  metadata {
    name = "payment-ns"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [helm_release.istiod]
}

resource "kubernetes_namespace" "cart_ns" {
  metadata {
    name = "cart-ns"
    labels = {
      "istio-injection" = "enabled"
    }
  }

  depends_on = [helm_release.istiod]
}
