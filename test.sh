set -Euo pipefail

suffix=$RANDOM
unset projects
declare -t projects=(
  "${PROJECT_PREFIX}-defaults-${suffix}"
  "${PROJECT_PREFIX}-defaults-rapid-${suffix}"
  "${PROJECT_PREFIX}-defaults-regular-${suffix}"
  "${PROJECT_PREFIX}-defaults-private-${suffix}"
  "${PROJECT_PREFIX}-defaults-private-rapid-${suffix}"
  "${PROJECT_PREFIX}-defaults-private-regular-${suffix}"
  "${PROJECT_PREFIX}-kitchen-sink-rapid-private-${suffix}"
  "${PROJECT_PREFIX}-kitchen-sink-regular-private-${suffix}"
  )

WORKDIR=`pwd`
pids=""
for project in ${projects[@]}; do
  echo "------------------Starting test ${project}.--------------------"
  
  echo "Creating project ${project}."
  gcloud projects create ${project} --folder ${FOLDER_ID}
  gcloud alpha billing projects link ${project} --billing-account ${BILLING_ID}
  echo "$project was created."
  
  DIR="tests/test-${project}"
  mkdir -p ${DIR}
  PATTERN=$(echo $project | sed -r 's/_/-/g').tf
  echo "Setting up test directory with ${PATTERN}"
  cp patterns/${PATTERN} ${DIR}

  echo "Created VPC, Secondary Subnets and KMS keys for testing."
  gcloud compute networks create default --project ${project} \
    --subnet-mode=auto \
    --bgp-routing-mode=global 

  gcloud compute networks subnets update default --project ${project} \
    --region=us-east1 \
    --add-secondary-ranges="cluster=10.1.0.0/20,svc=10.0.0.0/20"
  13578  gcloud kms keyrings create gke \\n    --location=us-central1 \\n    --project=tf-gke-test-01
  gcloud kms keys create gke --location=us-central1 --keyring=gke --purpose=encryption --project ${project}
  PROJECT_NUMBER=$(gcloud projects describe ${project} --format="value(projectNumber)")
  gcloud kms keys add-iam-policy-binding gke --location=us-central1 --project=tf-gke-test-01 \
    --keyring=gke \
    --member="serviceAccount:service-${PROJECT_NUMBER}@container-engine-robot.iam.gserviceaccount.com" \
    --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
  KEY_NAME="projects/${project}/locations/us-central1/keyRings/gke/cryptoKeys/gke"

  echo "Running terraform init"
  cd ${DIR}
  TF_LOG_PATH="${WORKDIR}/${PATTERN}.log"
  terraform init

  echo "Starting terraform plan process for ${project}"
  ( terraform apply -auto-approve ) &
  pid=$!
  pids+=" ${pid}"
  echo "${pid}: Running: $project"
  cd ${WORKDIR}
done

for p in $pids; do
  if wait $p; then
    echo "Terraform apply process $p succeeded"
  else
    echo "Terraform apply process $p failed. Apply aborted."
    echo "Killing any running concurrent commands."
    kill $p &> /dev/null
  fi
done

cat <<EOF >> source.sh
  export DEFAULTS_PROJECT="${PROJECT_PREFIX}-defaults-${suffix}"
  export DEFAULTS_RAPID_PROJECT="${PROJECT_PREFIX}-defaults-rapid-${suffix}"
  export DEFAULTS_REGULAR_PROJECT="${PROJECT_PREFIX}-defaults-regular-${suffix}"
  export DEFAULTS_PRIVATE_PROJECT="${PROJECT_PREFIX}-defaults-private-${suffix}"
  export DEFAULTS_PRIVATE_RAPID_PROJECT="${PROJECT_PREFIX}-defaults-private-rapid-${suffix}"
  export DEFAULTS_PRIVATE_REGULAR_PROJECT="${PROJECT_PREFIX}-defaults-private-regular-${suffix}"
  export KITCHEN_SINK_RAPID_PRIVATE="${PROJECT_PREFIX}-kitchen-sink-rapid-private-${suffix}"
  export KITCHEN_SINK_RREGULAR_PRIVATE="${PROJECT_PREFIX}-kitchen-sink-regular-private-${suffix}"
EOF