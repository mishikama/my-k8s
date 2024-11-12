data "yandex_client_config" "client" {}

locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
}

module "network" {
  source        = "git::https://github.com/terraform-yc-modules/terraform-yc-vpc"
  network_name  = "vpc-cloud"
  create_vpc    = true
  create_nat_gw = true

  private_subnets = [
    {
      name           = "private"
      v4_cidr_blocks = var.network.subnets
      zone           = var.zone
    }
  ]
}

module "kube" {
  source     = "git::https://github.com/terraform-yc-modules/terraform-yc-kubernetes/"
  network_id = module.network.vpc_id

  master_locations = [
    {
      zone      = var.zone
      subnet_id = module.network.private_subnets[var.network.subnets[0]].subnet_id
    }
  ]

  node_groups = {
    "yc-k8s-ng-01" = {
      platform_id = "standard-v3"
      node_cores  = 4
      node_memory = 4
      disk_type   = "network-hdd"
      disk_size   = 32
      preemptible = true
      nat         = false
      fixed_scale = {
        size = 2
      }
    }
  }
}

provider "kubernetes" {
  host                   = module.kube.external_v4_endpoint
  cluster_ca_certificate = module.kube.cluster_ca_certificate
}

resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "kubernetes_secret" "git_auth" {
  depends_on = [
    module.kube,
    kubernetes_namespace.flux_system
  ]

  metadata {
    name      = "git-auth"
    namespace = "flux-system"
  }

  data = {
    username = var.git_username
    password = var.git_token
  }

  type = "Opaque"
}

provider "helm" {
  kubernetes {
    host                   = module.kube.external_v4_endpoint
    cluster_ca_certificate = module.kube.cluster_ca_certificate
  }
}

resource "helm_release" "flux_operator" {
  depends_on       = [module.kube]
  name             = "flux-operator"
  namespace        = "flux-system"
  repository       = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart            = "flux-operator"
  create_namespace = true
}

resource "helm_release" "flux_instance" {
  depends_on = [
    helm_release.flux_operator,
    kubernetes_secret.git_auth
  ]

  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"

  set {
    name  = "instance.sync.kind"
    value = "GitRepository"
  }
  set {
    name  = "instance.sync.url"
    value = var.git_url
  }
  set {
    name  = "instance.sync.path"
    value = var.git_path
  }
  set {
    name  = "instance.sync.ref"
    value = var.git_ref
  }
  set {
    name  = "instance.sync.pullSecret"
    value = (var.git_username != "" && var.git_token != "") ? "git-auth" : ""
  }

  values = [
    file("values/components.yaml")
  ]
}
