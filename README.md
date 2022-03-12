# CI Pipeline Builder

## Overview
This example is used to bootstrap a CI pipeline for Infrastructure as a Code using Terraform in an existing GCP project that you have access to.

## [Bootstrap CI Pipeline](00-bootstrap-ci-project/)

You can use Google Cloud Shell for bootstrapping the CI Pipeline into existing GCP project or from your local machine. The Terraform configurations are tested using Terraform 1.0.0 and will deploy Cloud Build, Cloud Source Repo, Terraform Service Accounts, Cloud Storage, and related IAM policies

### Pre-requisites

1. A user account or service account who will execute the deployment is assigned with the following minimum IAM roles at the GCP project to bootstrap CI Pipeline.

    1. IAM roles Source Repository Administrator (roles/source.admin).

    1. IAM roles Service Usage Admin (roles/roles/serviceusage.serviceUsageAdmin)

    1. IAM roles Service Account Admin (roles/iam.serviceAccountAdmin)

    1. IAM roles Service Account User 

    1. IAM roles Cloud Build Editor

    1. IAM roles Project IAM Admin

    1. IAM roles Storage Admin

    1. IAM roles Compute Admin


1. Clone this repo

    ```bash
    cd ~
    git clone https://github.com/hyperionian/terraform-cloudbuild-configsync.git
    ```

### Deploy the CI Pipeline

**Terraform Inputs**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| project_id | Project ID where the CI Pipeline is deployed. | `string` | n/a | yes |
| default_region| Region for the CI PIpeline  | `string` | australila-southeast1 | yes |


1. Change into [00-bootstrap-ci-project](00-bootstrap-ci-project/)

    ```bash
    cd terraform-cloudbuild-configsync/security/ci-pipeline/00-bootstrap-ci-project
    ```

1. Copy terraform.tfvars.example file as terraform.tfvars, update the `project_id` with CI Pipeline project ID and `default_region` with location in where the CI Pipeline resources would be deployed
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```
   Update the following variables to 

    `project_id= "your-project-id"`

    `default_region= "australia-southeast2"`

   Add additional variables in `terraform.tfvars` to override the variables' value defined in `variable.tf` if required


1. Make sure that you are in [00-bootstrap-ci-project](00-bootstrap-ci-project/) directory, apply the Terraform configurations to deploy the CI Pipeline 

    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

### Deploy GCE resource using the CI Pipeline

In this example, we are deplyoing compute resource into the same project as the CI pipeline in `us-central1-a` zone

1. Clone the new Cloud Source Repo created. In this example, the cloud source repo name is `app-infra` and the project name we referred for the CI Pipeline is `your-project-id`. Ignore the warning "You appear to have cloned an empty repository"
    ```bash
    cd ~
    export REPO_NAME=app-infra
    export PROJECT_ID=your-project-id
    gcloud source repos clone app-infra --project=your-project-id
    ```

1. Navigate to the repo and change to a non prod branch, for example `dev` branch
   ```bash
   cd $REPO_NAME
   git checkout -b dev
   ```


1. Copy contents of [sample-compute](sample-compute/) to the new app-infra repo. `sample-compute` directory contains Terraform configurations example to deploy compute resource using the new CI Pipeline. You can create other resources by adding Terraform configurations into a new directory. Cloud Build will test and/or deploy any resources defined in sub-directories under app-infra/ directory
    ```bash
    cp -R ~/terraform-cloudbuild-configsync/security/ci-pipeline/sample-compute .
    ```
1. Update terraform.tfvars file under sample-compute directory to the project ID where the GCE instance will be deployed. In this example it will be the same project as the CI pipeline `your-project-id`
    ```bash
    project_id="your-proejct-id"
    ```

1. Copy Cloud Build configuration files [build-config](build-config/) for Terraform
    ```bash
    cp -R ~terraform-cloudbuild-configsync/build-config/cloudbuild-* .
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
1. Verify that the CI Pipeline build is completed successfully and a GCE instance is created through Cloud Console
