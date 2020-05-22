/**
 * Copyright 2018 Google LLC
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

locals {
  cluster_type = "simple-regional-asm2"
}

provider "google-beta" {
  version = "~> 3.19.0"
  region  = var.region
}

data "google_project" "project" {
  project_id = var.project_id
}

module "gke" {
  source     = "../../modules/beta-public-cluster/"
  project_id = var.project_id
  name       = "${local.cluster_type}-cluster${var.cluster_name_suffix}"
  regional   = true
  #TESTING
  release_channel         = "REGULAR"
  region                  = var.region
  network                 = var.network
  subnetwork              = var.subnetwork
  ip_range_pods           = var.ip_range_pods
  ip_range_services       = var.ip_range_services
  network_policy          = false
  cluster_resource_labels = { "mesh_id" : "proj-${data.google_project.project.number}" }
  node_pools = [
    {
      name         = "asm-node-pool"
      machine_type = "n1-standard-4"
      min_count    = 6
    },
  ]
}

module "asm" {
  source       = "../../modules/asm"
  cluster_name = module.gke.name
  project_id   = var.project_id
  location     = module.gke.location
}

data "google_client_config" "default" {
}
