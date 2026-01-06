/*
Main Terraform resource for DigitalOcean Kubernetes cluster
- Uses variables defined in variables.tf
- Outputs are handled in outputs.tf
*/

resource "digitalocean_kubernetes_cluster" "primary" {
  name         = var.cluster_name
  region       = var.cluster_region
  version      = var.kubernetes_version
  auto_upgrade = true

  node_pool {
    name       = var.node_pool_name
    size       = var.node_pool_size
    node_count = var.node_pool_count
    auto_scale = var.auto_scale
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes

    tags = ["worker"]
  }

  tags = ["kubernetes", "devops"]
}
