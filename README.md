# CI Pipeline Builder

## Overview
This Terraform Configuration example is used to bootstrap a CI pipeline for IaC deployment by creating a new CI pipeline project under Organization you have access to.

## [Bootstrap CI Pipeline](00-bootstrap-ci-project/)

You can use Google Cloud Shell for bootstrapping the CI Pipeline into existing GCP project or from your local machine. The Terraform configurations are tested using Terraform 1.0.0 and will deploy Cloud Build, Cloud Source Repo, Terraform Service Accounts, Cloud Storage, and related IAM policies

### Pre-requisites

1. A user account or service account who will execute the deployment is assigned with the following IAM roles

- The roles/resourcemanager.organizationAdmin role on the Google Cloud organization
- The roles/billing.admin role on the billing account


1. Clone this repo
    ```
    cd ~
    git clone https://github.com/hyperionian/terraform-cloudbuild-configsync.git
    ```

### Deploy the CI Pipeline

**Terraform Required Inputs**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| org_id | Org ID where the CI pipeline is deployed. | `string` | | yes |
| billing_account| Billing account for the new CI pipeline project  | `string` | | yes|
| group_org_admins | Google Groups for Org admin users | `string` | n/a | yes |
| default_region| Region for the CI pipeline components such as Cloud Storage, Artifact Registry| `string` | us-central1 | yes |


1. Change into [00-bootstrap-ci-project](00-bootstrap-ci-project/)

    ```bash
    cd terraform-cloudbuild-configsync/00-bootstrap-ci-project
    ```

1. Copy terraform.tfvars.example file as terraform.tfvars, update the variables for bootstraping the CI pipeline projects and resources

    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

   Add additional variables in `terraform.tfvars` to override the variables' value defined in `variable.tf` if required


1. Make sure that you are in [00-bootstrap-ci-project](00-bootstrap-ci-project/) directory, apply the Terraform configurations to deploy the CI Pipeline 

    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

### Deploy sample infrastructure using Cloud Build in the newly created CI pipeline project

In this example, we are deplyoing **sample** infrastructure that consists of 2 GKE clusters, enable Config Sync, Policy Controller into the same project as the CI pipeline

1. Clone the new Cloud Source Repo created. In this example, the cloud source repo name is `app-infra`. Replace the `ci-project-id` with the new CI pipeline project ID. Ignore the warning "You appear to have cloned an empty repository"

    ```bash
    cd ~
    export REPO_NAME=app-infra
    export PROJECT_ID=ci-project-id
    gcloud source repos clone app-infra --project=<ci-project-id>
    ```

1. Navigate to the repo and change to a non prod branch, for example `dev` branch
   ```bash
   cd $REPO_NAME
   git checkout -b dev
   ```


1. Copy contents of [gke-configsync](gke-configsync/) to the new app-infra repo. `gke-configsync` directory contains Terraform configurations example to deploy compute resource using the new CI Pipeline. You can create other resources by adding Terraform configurations into a new directory. Cloud Build will test and/or deploy any resources defined in sub-directories under app-infra/ directory
    ```bash
    cp -R ~/terraform-cloudbuild-configsync/gke-configsync .
    ```
1. Rename terraform.tfvars.example as terraform.tfvars file under gke-configsync directory and update it with the  project ID where the GKE clusters will be deployed and Node Pool service account to use. In this example, it would be the same project as the CI pipeline project and the service account for the Node pool would be the new  service account created by the bootstrap configurations. It usually has the service account email in the format of project-service-account@\<ci-project-id\>.iam.gserviceaccount.com

    ```bash
    project_id = <ci-project-id>
    compute_serviceaccount = project-service-account@<ci-project-id>.iam.gserviceaccount.com
    ```
    
    Replace `ci-project-id` with the new CI pipeline project ID
1. Rename backend.tf.example file as backend.tf

1. Copy Cloud Build configuration files in [build](build/) to the new app-infra repo.

    ```bash
    cp -R ~terraform-cloudbuild-configsync/build/cloudbuild-* .
    ```
1. Commit your changes
    ```bash
    git add .
    git commit -m "Your commit message"
    ```
1. Push to dev branch
    ```bash
    git push origin dev
    ```
1. Review the plan output in the Cloud Build History through Cloud Console

1. Merge the changes to Production branch. Pushing to this branch will trigger `terraform plan` and `terraform apply`
    ```bash
    git checkout -b main
    git push origin main
    ```
1. Verify that the CI Pipeline build is completed successfully and the GKE clusters are deployed successfully with Config Sync enabled, and Config objects are synced to the new cluster. You can check the status of the CI Pipeline build in the Cloud Console

> ConfigSync is configured to sync the config objects to the new cluster using the Root repo (unstructured) from this sample [repository](https://github.com/hyperionian/config-management) under `config-root` directory.