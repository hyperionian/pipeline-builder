/******************************************
  Required variables
*******************************************/

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account" {
  description = "The ID of the billing account to associate projects with."
  type        = string
}

variable "group_org_admins" {
  description = "Google Group for GCP Organization Administrators"
  type        = string
}

variable "default_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "us-central1"
}

variable "state_bucket_name" {
  description = "Custom state bucket name. If not supplied, the default name is {project_prefix}-tfstate-{random suffix}."
  default     = ""
  type        = string
}

variable "tf_service_account_id" {
  description = "ID of service account for terraform in seed project"
  type        = string
  default     = "terraform-org"
}

variable "tf_service_account_name" {
  description = "Display name of service account for terraform in seed project"
  type        = string
  default     = "Organization Terraform Account"
}

/******************************************
  Optional variables
*******************************************/

variable "project_labels" {
  description = "Labels to apply to the project."
  type        = map(string)
  default     = {}
}

variable "project_prefix" {
  description = "Name prefix to use for projects created."
  type        = string
  default     = "cb"
}

variable "project_id" {
  description = "Custom project ID to use for project created."
  default     = ""
  type        = string
}

variable "activate_apis" {
  description = "List of APIs to enable in the Cloudbuild project."
  type        = list(string)

  default = [
    "serviceusage.googleapis.com",
    "servicenetworking.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "admin.googleapis.com",
    "appengine.googleapis.com",
    "storage-api.googleapis.com"
  ]
}

variable "sa_org_iam_permissions" {
  description = "List of permissions granted to Terraform service account across the GCP organization."
  type        = list(string)
  default = [
    "roles/compute.networkAdmin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/logging.configWriter",
    "roles/compute.admin",
    "roles/pubsub.editor",
    "roles/cloudfunctions.developer",
    "roles/storage.admin"
  ]
}
variable "sa_enable_impersonation" {
  description = "Allow org_admins group to impersonate service account & enable APIs required."
  type        = bool
  default     = false
}

variable "storage_bucket_labels" {
  description = "Labels to apply to the storage bucket."
  type        = map(string)
  default     = {}
}

variable "create_cloud_source_repos" {
  description = "If shared Cloud Source Repos should be created."
  type        = bool
  default     = true
}

variable "cloud_source_repos" {
  description = "List of Cloud Source Repos to create with CloudBuild triggers."
  type        = list(string)

  default = [
    "app-infra"
  ]
}

variable "folder_id" {
  description = "The ID of a folder to host this project"
  type        = string
  default     = ""
}

variable "encrypt_gcs_bucket_tfstate" {
  description = "Encrypt bucket used for storing terraform state files in seed project."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "If supplied, the state bucket will be deleted even while containing objects."
  type        = bool
  default     = false
}

variable "key_protection_level" {
  type        = string
  description = "The protection level to use when creating a version based on this template. Default value: \"SOFTWARE\" Possible values: [\"SOFTWARE\", \"HSM\"]"
  default     = "SOFTWARE"
}

variable "key_rotation_period" {
  type    = string
  default = null
}

variable "kms_prevent_destroy" {
  description = "Set the prevent_destroy lifecycle attribute on keys."
  default     = true
}

variable "terraform_version" {
  description = "Default terraform version."
  type        = string
  default     = "1.0.2"
}

variable "terraform_version_sha256sum" {
  description = "sha256sum for default terraform version."
  type        = string
  default     = "7329f887cc5a5bda4bedaec59c439a4af7ea0465f83e3c1b0f4d04951e1181f4"
}

variable "terraform_validator_release" {
  description = "Default terraform-validator release."
  type        = string
  default     = "v0.4.0"
}

variable "cloudbuild_plan_filename" {
  description = "Path and name of Cloud Build Config file definition used for terraform plan."
  type        = string
  default     = "cloudbuild-tf-plan.yaml"
}

variable "cloudbuild_apply_filename" {
  description = "Path and name of Cloud Build Config definition used for terraform apply."
  type        = string
  default     = "cloudbuild-tf-apply.yaml"
}

variable "terraform_apply_branches" {
  description = "List of git branches configured to run terraform apply Cloud Build trigger. All other branches will run terraform plan."
  type        = list(string)
  default = [
    "main"
  ]
}

variable "gar_repo_name" {
  description = "Custom name to use for GAR repo."
  default     = ""
  type        = string
}

variable "random_suffix" {
  description = "Appends a 4 character random suffix to project ID and GCS bucket name."
  type        = bool
  default     = true
}
