#!/usr/bin/env bash

set -Euo pipefail

while getopts n:r: flag
do
  case "${flag}" in
      n) CLUSTER_NAME=${OPTARG};;
      r) RELEASE_CHANNEL=${OPTARG};;
  esac
done

echo "::Variable set::"
echo "CLUSTER_NAME: ${CLUSTER_NAME}"
echo "RELEASE_CHANNEL: ${RELEASE_CHANNEL}" ## regular or rapid

if [[ ${RELEASE_CHANNEL} == "regular" ]]; then
    gcloud container clusters create ${CLUSTER_NAME} \
        --zone us-central1-b \
        --release-channel=regular \
        --scopes=cloud-platform \
        --service-account="gke-toolkit-sa@fleets-argo-demo.iam.gserviceaccount.com"
elif [[ ${RELEASE_CHANNEL} == "rapid" ]]; then
    gcloud container clusters create ${CLUSTER_NAME} \
        --zone us-central1-b \
        --release-channel=rapid \
        --scopes=cloud-platform \
        --service-account="gke-toolkit-sa@fleets-argo-demo.iam.gserviceaccount.com"
else
    gcloud container clusters create ${CLUSTER_NAME} \
        --zone us-central1-b \
        --cluster-version=1.22.12-gke.2300 \
        --scopes=cloud-platform \
        --service-account="gke-toolkit-sa@fleets-argo-demo.iam.gserviceaccount.com"
fi