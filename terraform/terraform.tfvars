cluster_name       = "devops-cluster"
cluster_region     = "nyc3"
kubernetes_version = "latest"
node_pool_name     = "worker-pool"
node_pool_size     = "s-2vcpu-2gb"
node_pool_count    = 1
auto_scale         = true
min_nodes          = 1
max_nodes          = 3

