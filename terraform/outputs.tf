output "cluster_id" {
  description = "Kubernetes cluster ID"
  value       = digitalocean_kubernetes_cluster.primary.id
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = digitalocean_kubernetes_cluster.primary.name
}

output "cluster_region" {
  description = "Kubernetes cluster region"
  value       = digitalocean_kubernetes_cluster.primary.region
}

output "cluster_status" {
  description = "Kubernetes cluster status"
  value       = digitalocean_kubernetes_cluster.primary.status
}

output "kubeconfig" {
  description = "Kubeconfig for kubectl access"
  value       = digitalocean_kubernetes_cluster.primary.kube_config[0].raw_config
  sensitive   = true
}

output "endpoint" {
  description = "Kubernetes cluster API endpoint"
  value       = digitalocean_kubernetes_cluster.primary.endpoint
}
