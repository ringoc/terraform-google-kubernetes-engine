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
ASM_RESOURCES="asm-dir"
BASE_DIR="asm-base-dir"
mkdir -p $ASM_RESOURCES
pushd $ASM_RESOURCES
gcloud config set project ${PROJECT_ID}
if [[ -d ./asm-patch ]]; then
    echo "ASM patch directory exists. Skipping download..."
else
    echo "Downloading ASM patch"
    kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm-patch@release-1.5-asm .
fi
anthoscli export -c ${CLUSTER_NAME} -o ${BASE_DIR} -p ${PROJECT_ID} -l ${CLUSTER_LOCATION}
kpt cfg set asm-patch/ base-dir ../${BASE_DIR}
kpt cfg set asm-patch/ gcloud.core.project ${PROJECT_ID}
kpt cfg set asm-patch/ gcloud.container.cluster ${CLUSTER_NAME}
kpt cfg set asm-patch/ gcloud.compute.location ${CLUSTER_LOCATION}
kpt cfg list-setters asm-patch/
pushd ${BASE_DIR} && kustomize create --autodetect --namespace ${PROJECT_ID} && popd
pushd asm-patch && kustomize build -o ../${BASE_DIR}/all.yaml && popd
kpt fn source ${BASE_DIR} | kpt fn run --image gcr.io/kustomize-functions/validate-asm:v0.1.0
anthoscli apply -f ${BASE_DIR}
kubectl wait --for=condition=available --timeout=600s deployment --all -n istio-system
