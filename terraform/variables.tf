#variable "digitalocean_token" {
#  description = "DigitalOcean API Token"
#  type        = string
#  sensitive   = true
#}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "devops-cluster"
}

variable "cluster_region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "latest"
}

variable "node_pool_name" {
  description = "Name of the node pool"
  type        = string
  default     = "worker-pool"
}

variable "node_pool_size" {
  description = "Size of nodes in the pool"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "node_pool_count" {
  description = "Number of nodes in the pool"
  type        = number
  default     = 3
}

variable "auto_scale" {
  description = "Enable auto-scaling"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

#variable "spaces_access_key" {
#  description = "DigitalOcean Spaces Access Key"
#  type        = string
#  sensitive   = true
#}

#variable "spaces_secret_key" {
#  description = "DigitalOcean Spaces Secret Key"
#  type        = string
#  sensitive   = true
#}
