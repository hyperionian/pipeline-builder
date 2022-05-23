/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  type        = string
  description = "the GCP project where the cluster will be created"
}

variable "compute_serviceaccount" {
  type        = string
  description = "the service account to use for the node pool"
}

variable "region" {
  type        = string
  description = "the GCP region where the platform cluster will be created"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "the GCP zone in the region where the platform admin cluster will be created"
  default     = "us-central1-f"
}

variable "gke_num_nodes" {
  default     = 4
  description = "number of gke nodes"
}