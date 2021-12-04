locals {
  generated_bucket_name = format("%s-%s-%s", var.project_prefix, "tfstate", random_id.suffix.hex)
  supplied_bucket_name  = format("%s-%s", var.state_bucket_name, random_id.suffix.hex)
  state_bucket_name     = var.state_bucket_name != "" ? local.supplied_bucket_name : local.generated_bucket_name

  cloudbuild_project_id       = var.project_id != "" ? var.project_id : format("%s-%s", var.project_prefix, "pipeline")
  gar_repo_name               = var.gar_repo_name != "" ? var.gar_repo_name : format("%s-%s", var.project_prefix, "tf-runners")
  cloudbuild_apis             = ["cloudbuild.googleapis.com", "sourcerepo.googleapis.com", "cloudkms.googleapis.com", "artifactregistry.googleapis.com"]
  impersonation_enabled_count = var.sa_enable_impersonation == true ? 1 : 0
  activate_apis               = distinct(concat(var.activate_apis, local.cloudbuild_apis))
  apply_branches_regex        = "^(${join("|", var.terraform_apply_branches)})$"
  gar_name                    = split("/", google_artifact_registry_repository.tf-image-repo.name)[length(split("/", google_artifact_registry_repository.tf-image-repo.name)) - 1]
}

resource "random_id" "suffix" {
  byte_length = 2
}

data "google_organization" "org" {
  organization = var.org_id
}

module "cloudbuild_project" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 10.1.1"
  name                        = local.cloudbuild_project_id
  random_project_id           = var.random_suffix
  disable_services_on_destroy = false
  org_id                      = var.org_id
  billing_account             = var.billing_account
  activate_apis               = local.activate_apis
  labels                      = var.project_labels
}

resource "google_service_account" "terraform_sa" {
  project      = module.cloudbuild_project.project_id
  account_id   = var.tf_service_account_id
  display_name = var.tf_service_account_name
}

data "google_storage_project_service_account" "gcs_account" {
  project = module.cloudbuild_project.project_id

  depends_on = [
    module.cloudbuild_project.project_id
  ]
}

module "kms" {
  count   = var.encrypt_gcs_bucket_tfstate ? 1 : 0
  source  = "terraform-google-modules/kms/google"
  version = "~> 1.2"

  project_id           = module.cloudbuild_project.project_id
  location             = var.default_region
  keyring              = "${var.project_prefix}-keyring"
  keys                 = ["${var.project_prefix}-key"]
  key_rotation_period  = var.key_rotation_period
  key_protection_level = var.key_protection_level
  set_decrypters_for   = ["${var.project_prefix}-key"]
  set_encrypters_for   = ["${var.project_prefix}-key"]
  decrypters = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
  ]
  encrypters = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
  ]
  prevent_destroy = var.kms_prevent_destroy
}

resource "google_storage_bucket" "org_terraform_state" {
  project                     = module.cloudbuild_project.project_id
  name                        = local.state_bucket_name
  location                    = var.default_region
  labels                      = var.storage_bucket_labels
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }

  dynamic "encryption" {
    for_each = var.encrypt_gcs_bucket_tfstate ? ["encryption"] : []
    content {
      default_kms_key_name = module.kms[0].keys["${var.project_prefix}-key"]
    }
  }
}

/*** Assign Project Level IAM Policy to Terraform Service Account  ***/

resource "google_project_iam_member" "tf_sa_perms" {
  for_each = toset(var.sa_org_iam_permissions)

  project = module.cloudbuild_project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

/*** Assign Storage Admin  to Terraform Service Account  ***/

resource "google_storage_bucket_iam_member" "tfsa_state_iam" {
  bucket = google_storage_bucket.org_terraform_state.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

/*** Allow Org Admin to impersonate Terraform Service Account  ***/

resource "google_service_account_iam_member" "org_admin_sa_impersonate_permissions" {
  count = local.impersonation_enabled_count

  service_account_id = google_service_account.terraform_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "group:${var.group_org_admins}"
}

resource "google_organization_iam_member" "org_admin_serviceusage_consumer" {
  count = local.impersonation_enabled_count

  org_id = var.org_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "group:${var.group_org_admins}"
}

resource "google_storage_bucket_iam_member" "orgadmins_state_iam" {
  count = local.impersonation_enabled_count

  bucket = google_storage_bucket.org_terraform_state.name
  role   = "roles/storage.admin"
  member = "group:${var.group_org_admins}"
}

/*** 
Cloud Build Pipeline 
***/
resource "google_project_iam_member" "org_admins_cloudbuild_editor" {
  project = module.cloudbuild_project.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "group:${var.group_org_admins}"
}

resource "google_project_iam_member" "org_admins_cloudbuild_viewer" {
  project = module.cloudbuild_project.project_id
  role    = "roles/viewer"
  member  = "group:${var.group_org_admins}"
}


resource "google_storage_bucket" "cloudbuild_artifacts" {
  project                     = module.cloudbuild_project.project_id
  name                        = format("%s-%s-%s", var.project_prefix, "cloudbuild-artifacts", random_id.suffix.hex)
  location                    = var.default_region
  labels                      = var.storage_bucket_labels
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

/******************************************
  KMS Keyring
 *****************************************/

resource "google_kms_key_ring" "tf_keyring" {
  project  = module.cloudbuild_project.project_id
  name     = "tf-keyring"
  location = var.default_region

  depends_on = [
    module.cloudbuild_project
  ]
}

/******************************************
  KMS Key
 *****************************************/

resource "google_kms_crypto_key" "tf_key" {
  name     = "tf-key"
  key_ring = google_kms_key_ring.tf_keyring.self_link
}

/******************************************
  Permissions to decrypt.
 *****************************************/

resource "google_kms_crypto_key_iam_binding" "cloudbuild_crypto_key_decrypter" {
  crypto_key_id = google_kms_crypto_key.tf_key.self_link
  role          = "roles/cloudkms.cryptoKeyDecrypter"

  members = [
    "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com",
    "serviceAccount:${google_service_account.terraform_sa.email}"
  ]
}

/******************************************
  Permissions for org admins to encrypt.
 *****************************************/

resource "google_kms_crypto_key_iam_binding" "cloud_build_crypto_key_encrypter" {
  crypto_key_id = google_kms_crypto_key.tf_key.self_link
  role          = "roles/cloudkms.cryptoKeyEncrypter"

  members = [
    "group:${var.group_org_admins}",
  ]
}

/******************************************
  Create Cloud Source Repos
*******************************************/

resource "google_sourcerepo_repository" "csr_git" {
  for_each = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []
  project  = module.cloudbuild_project.project_id
  name     = each.value
}

/*** Cloud Source Repo Project level IAM policy ***/

resource "google_project_iam_member" "org_admins_source_repo_admin" {
  count   = var.create_cloud_source_repos ? 1 : 0
  project = module.cloudbuild_project.project_id
  role    = "roles/source.admin"
  member  = "group:${var.group_org_admins}"
}

/***********************************************
 Cloud Build - Main branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "main_trigger" {
  for_each    = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []
  project     = module.cloudbuild_project.project_id
  description = "${each.value} - terraform apply."

  trigger_template {
    branch_name = local.apply_branches_regex
    repo_name   = each.value
  }

  substitutions = {
    _ORG_ID               = var.org_id
    _BILLING_ID           = var.billing_account
    _DEFAULT_REGION       = var.default_region
    _GAR_REPOSITORY       = local.gar_name
    _TF_SA_EMAIL          = google_service_account.terraform_sa.email
    _STATE_BUCKET_NAME    = google_storage_bucket.org_terraform_state.name
    _ARTIFACT_BUCKET_NAME = google_storage_bucket.cloudbuild_artifacts.name
    _TF_ACTION            = "apply"
  }

  filename = var.cloudbuild_apply_filename
  depends_on = [
    google_sourcerepo_repository.csr_git
  ]
}

/***********************************************
 Cloud Build - Non Main branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "non_main_trigger" {
  for_each    = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []
  project     = module.cloudbuild_project.project_id
  description = "${each.value} - terraform plan."

  trigger_template {
    invert_regex = true
    branch_name  = local.apply_branches_regex
    repo_name    = each.value
  }

  substitutions = {
    _ORG_ID               = var.org_id
    _BILLING_ID           = var.billing_account
    _DEFAULT_REGION       = var.default_region
    _GAR_REPOSITORY       = local.gar_name
    _TF_SA_EMAIL          = google_service_account.terraform_sa.email
    _STATE_BUCKET_NAME    = google_storage_bucket.org_terraform_state.name
    _ARTIFACT_BUCKET_NAME = google_storage_bucket.cloudbuild_artifacts.name
    _TF_ACTION            = "plan"
  }

  filename = var.cloudbuild_plan_filename
  depends_on = [
    google_sourcerepo_repository.csr_git,
  ]
}

/***********************************************
 Cloud Build - Terraform Image Repo
 ***********************************************/

resource "google_artifact_registry_repository" "tf-image-repo" {
  provider = google-beta
  project  = module.cloudbuild_project.project_id

  location      = var.default_region
  repository_id = local.gar_repo_name
  description   = "Docker repository for Terraform runner images used by Cloud Build"
  format        = "DOCKER"
}

/***********************************************
 Cloud Build - Terraform builder
 ***********************************************/

resource "null_resource" "cloudbuild_terraform_builder" {
  triggers = {
    project_id_cloudbuild_project = module.cloudbuild_project.project_id
    terraform_version_sha256sum   = var.terraform_version_sha256sum
    terraform_version             = var.terraform_version
    gar_name                      = local.gar_name
    gar_location                  = google_artifact_registry_repository.tf-image-repo.location
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit ${path.module}/cloudbuild_builder/ \
      --project ${module.cloudbuild_project.project_id} \
      --config=${path.module}/cloudbuild_builder/cloudbuild.yaml \
      --substitutions=_TERRAFORM_VERSION=${var.terraform_version},_TERRAFORM_VERSION_SHA256SUM=${var.terraform_version_sha256sum},_TERRAFORM_VALIDATOR_RELEASE=${var.terraform_validator_release},_REGION=${google_artifact_registry_repository.tf-image-repo.location},_REPOSITORY=${local.gar_name}
  EOT
  }
  depends_on = [
    google_artifact_registry_repository_iam_member.terraform-image-iam
  ]
}

/***Cloud Build artefacts - IAM Policy ***/

resource "google_storage_bucket_iam_member" "cloudbuild_artifacts_iam" {
  bucket = google_storage_bucket.cloudbuild_artifacts.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_artifact_registry_repository_iam_member" "terraform-image-iam" {
  provider = google-beta
  project  = module.cloudbuild_project.project_id

  location   = google_artifact_registry_repository.tf-image-repo.location
  repository = google_artifact_registry_repository.tf-image-repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}

/*** Assign Cloud Build project level IAM policy ***/

resource "google_project_iam_member" "cb_sa_perms" {
  for_each = toset(var.cb_project_iam_permissions)
  project  = module.cloudbuild_project.project_id
  role     = each.value
  member   = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}

/*** Allow Cloud Build to impersonate Terraform service account only ***/

resource "google_service_account_iam_member" "cloudbuild_terraform_sa_impersonate_permissions" {
  count = local.impersonation_enabled_count

  service_account_id = google_service_account.terraform_sa.email
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_organization_iam_member" "cloudbuild_serviceusage_consumer" {
  count = local.impersonation_enabled_count

  org_id = var.org_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}

# Required to allow cloud build to access state with impersonation.

resource "google_storage_bucket_iam_member" "cloudbuild_state_iam" {
  count = local.impersonation_enabled_count

  bucket = google_storage_bucket.org_terraform_state.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}