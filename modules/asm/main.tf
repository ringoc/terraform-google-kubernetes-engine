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

module "asm_install" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 1.0"

  platform                          = "linux"
  gcloud_sdk_version                = "292.0.0"
  skip_download                     = var.skip_gcloud_download
  upgrade                           = false
  use_tf_google_credentials_env_var = true
  additional_components             = ["kubectl", "kpt", "anthoscli", "alpha"]

  create_cmd_entrypoint  = "${path.module}/scripts/install_asm.sh"
  create_cmd_body        = "${var.project_id} ${var.cluster_name} ${var.location} ${var.asm_release_channel}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "version"
}

resource "google_service_account" "gke_hub_sa" {
  account_id   = "gke-hub-sa"
  display_name = "Service Account"
}

resource "google_project_iam_member" "gke_hub_member" {
  project = var.project_id
  role    = "roles/gkehub.connect"
  member  = "serviceAccount:${google_service_account.gke_hub_sa.email}"
}
