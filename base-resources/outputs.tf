output "kubernetes_platform_cluster_name" {
  value       = google_container_cluster.platform.name
  description = "GKE Platform Admin Cluster Name"
}

output "kubernetes_dev_cluster_name" {
  value       = google_container_cluster.dev.name
  description = "GKE Dev Cluster Name"
}

output "kubernetes_platform_cluster_location" {
  value       = google_container_cluster.platform.location
  description = "GKE Platform Admin Cluster location"
}

output "kubernetes_dev_cluster_location" {
  value       = google_container_cluster.dev.location
  description = "GKE Dev Cluster location"
}

output "kubernetes_platform_cluster_id" {
  value       = google_container_cluster.platform.id
  description = "GKE Platform Admin Cluster ID"
}

output "kubernetes_dev_cluster_id" {
  value       = google_container_cluster.dev.id
  description = "GKE Platform Dev Cluster ID"
}

output "gcp_service_account_name_my_dev" {
  value       = module.k8s_sa_dev.gcp_service_account_name
  description = "GCP service account name"
}

output "gcp_service_account_email_my_dev" {
  value       = module.k8s_sa_dev.gcp_service_account_email
  description = "GCP service account name"
}

output "gcp_service_account_fqn_my_dev" {
  value       = module.k8s_sa_dev.gcp_service_account_fqn
  description = "GCP service account name"
}

output "Kubernetes_Service_Account_Name_my_dev" {
  value       = module.k8s_sa_platform.k8s_service_account_name
  description = "Kubernetes Service Account Name"
}

output "project_number" {
  value       = data.google_project.project_number.number
  description = "Project Number"
}