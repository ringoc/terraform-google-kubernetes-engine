#!/bin/bash
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

if [ "$#" -lt 4 ]; then
    >&2 echo "Not all expected arguments set."
    exit 1
fi

PROJECT_ID=$1
CLUSTER_NAME=$2
CLUSTER_LOCATION=$3
ASM_CHANNEL=$4

if [[ -d ./asm ]]; then
    echo "Removing kpt asm directory"
    rm -rf ./asm
fi
gcloud config set project ${PROJECT_ID}
# gcloud auth list
gcloud services enable meshca.googleapis.com
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm .
kpt cfg set asm gcloud.core.project ${PROJECT_ID}
kpt cfg set asm cluster-name ${CLUSTER_NAME}
kpt cfg set asm gcloud.compute.zone ${CLUSTER_LOCATION}
kpt cfg set asm gcloud.container.cluster.releaseChannel ${ASM_CHANNEL}
anthoscli apply -f asm
kubectl wait --for=condition=available --timeout=600s deployment --all -n istio-system
