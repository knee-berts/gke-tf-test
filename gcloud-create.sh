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

export PROJECT_ID=fleets-argo-demo
if [[ ${RELEASE_CHANNEL} == "regular" ]]; then
    gcloud container clusters create ${CLUSTER_NAME} --project ${PROJECT_ID} \
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
elif [[ ${RELEASE_CHANNEL} == "kitchensink" ]]; then
    gcloud container clusters create ${CLUSTER_NAME} --project ${PROJECT_ID} \
        --zone us-central1-b \
        --release-channel=rapid \
        --scopes=cloud-platform \
        --enable-ip-alias \
        --enable-autoscaling --min-nodes "1" --max-nodes "10" \
        --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 \
        --autoscaling-profile optimize-utilization \
        --workload-pool "${PROJECT_ID}.svc.id.goog" \
        --enable-master-authorized-networks \
        --master-authorized-networks 0.0.0.0/0 \
        --master-ipv4-cidr 172.16.1.16/28 \
        --enable-private-nodes \
        --enable-master-authorized-networks \
        --master-authorized-networks 10.0.0.0/12 \
        --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM,API_SERVER \
        --shielded-integrity-monitoring --shielded-secure-boot \
        --enable-master-global-access \
        --service-account="gke-toolkit-sa@fleets-argo-demo.iam.gserviceaccount.com"
else
    gcloud container clusters create ${CLUSTER_NAME} --project ${PROJECT_ID} \
        --zone us-central1-b \
        --cluster-version=1.22.12-gke.2300 \
        --scopes=cloud-platform \
        --service-account="gke-toolkit-sa@fleets-argo-demo.iam.gserviceaccount.com"
fi
