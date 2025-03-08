terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.8.0"
    }
  }
}

provider "kind" {
  # Configuration options
}


resource "kind_cluster" "c2" {
  name           = "c2"
  node_image     = "kindest/node:v1.32.2"
  wait_for_ready = true
  timeouts {
    create = "200m"
    delete = "200m"
  }

  kind_config {
    api_version = "kind.x-k8s.io/v1alpha4"
    kind        = "Cluster"
    node {
      role = "control-plane"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 30080
        host_port      = 8080
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }
  }

}

provider "helm" {
  kubernetes {
    config_path = kind_cluster.c2.kubeconfig_path
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version = "4.5.2"

  create_namespace = true

 set {
    name  = "server.service.type"
    value = "NodePort"
  }


}


# [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("=="))
