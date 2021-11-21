variable "project_id" {
  type        = string
  description = "Project ID of the K8S clusters"
  default     = ""
}

variable "k8shost" {
  type        = string
  description = "The Kubernetes API server host"
  default     = ""
}

variable "clustercacert" {
  type        = string
  description = "the cluster CA Cert"
  default     = ""
}

variable "clustername" {
  type        = string
  description = "Cluster Name"
  default     = ""
}