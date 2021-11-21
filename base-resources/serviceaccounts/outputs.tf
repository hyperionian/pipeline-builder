output "gcp_service_account" {
  description = "GCP service account"
  value       = module.workload-identity.gcp_service_account
}

output "gcp_service_account_name" {
  description = "GCP service account name"
  value       = module.workload-identity.gcp_service_account_name
}

output "gcp_service_account_fqn" {
  description = "GCP service account name"
  value       = module.workload-identity.gcp_service_account_fqn
}

output "gcp_service_account_email" {
  description = "GCP service account name"
  value       = module.workload-identity.gcp_service_account_email
}

output "k8s_service_account_name" {
  description = "Kubernetes Service Account name"
  value       = module.workload-identity.k8s_service_account_name
}


