  #!/usr/bin/env bash

set -Euo pipefail

while getopts p: flag
do
  case "${flag}" in
      p) project=${OPTARG};;
  esac
done

echo "::Variable set::"
echo "PROJECT_ID: ${project}"
  
echo "------------------Starting test ${project}.--------------------"

echo "Creating project ${project}."
gcloud projects create ${project} --folder ${FOLDER_ID}
gcloud alpha billing projects link ${project} --billing-account ${BILLING_ID}
echo "$project was created."

echo "Enabling GCP APIs"
gcloud services enable \
  --project=${project} \
  container.googleapis.com \
  compute.googleapis.com \
  cloudkms.googleapis.com

DIR="tests/test-${project}"
PATTERN=$(echo $project | awk -F "-"  '{$1=$(NF)=""; print $0}' | xargs | sed -r 's/ /_/g').tf
echo "Setting up test directory with ${PATTERN}"
cp patterns/${PATTERN} ${DIR}

echo "Creating VPC, Secondary Subnets and KMS keys for testing."
gcloud compute networks create default --project ${project} \
  --subnet-mode=auto \
  --bgp-routing-mode=global 

gcloud compute networks subnets update default --project ${project} \
  --region=us-central1 \
  --add-secondary-ranges="cluster=10.1.0.0/20,svc=10.0.0.0/20"
gcloud kms keyrings create gke --location=us-central1 --project=${project}
gcloud kms keys create gke --location=us-central1 --keyring=gke --purpose=encryption --project ${project}
PROJECT_NUMBER=$(gcloud projects describe ${project} --format="value(projectNumber)")
gcloud kms keys add-iam-policy-binding gke --location=us-central1  --project=${project} \
  --keyring=gke \
  --member="serviceAccount:service-${PROJECT_NUMBER}@container-engine-robot.iam.gserviceaccount.com" \
  --role=roles/cloudkms.cryptoKeyEncrypterDecrypter

echo "Running terraform init"
cd ${DIR}
export TF_LOG="INFO"
export TF_LOG_PATH="${project}.log"
terraform init

echo "Starting terraform plan process for ${project}"
terraform apply -var="project_id=${project}" -auto-approve &
