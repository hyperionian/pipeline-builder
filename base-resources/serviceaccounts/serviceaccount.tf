
# Create GCP Service Account and K8S Service Account to GKE Platform admin cluster, annotate K8S SA to GCP SA, and assign K8S SA as workloadIdentityUser role using workload-identity module 
# Refer to https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/v16.1.0/modules/workload-identity

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = var.k8shost
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(var.clustercacert)
}

module "workload-identity" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name                = "sa-${var.clustername}"
  namespace           = "default"
  project_id          = var.project_id
  use_existing_k8s_sa = false
  roles               = ["roles/storage.admin", "roles/compute.admin"]
}