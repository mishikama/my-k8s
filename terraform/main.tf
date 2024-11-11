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
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-kubernetes/"

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

resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace.flux_system]

  name       = "flux-operator"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
  wait       = true
}

// Configure the Flux instance.
resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator]

  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"

  // Configure the Flux components and kustomize patches.
  values = [
    file("values/components.yaml")
  ]
}
