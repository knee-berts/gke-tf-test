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
  )

WORKDIR=`pwd`
pids=""
for project in ${projects[@]}; do
  echo "------------------Starting test ${project}.--------------------"
  
  echo "Creating project ${project}."
  gcloud projects create ${project} --folder ${FOLDER_ID}
  gcloud alpha billing projects link ${project} --billing-account ${BILLING_ID}
  echo "$project was created."
  
  DIR="test-${project}"
  mkdir ${DIR}
  PATTERN=$(echo $project | sed -r 's/_/-/g').tf
  echo "Setting up test directory with ${PATTERN}"
  cp patterns/${PATTERN} ${DIR}

  echo "Running terraform init"
  cd ${DIR}
  TF_LOG_PATH="${WORKDIR}/${PATTERN}.log"
  terraform init

  echo "Starting terraform plan process for ${project}"
  ( terraform apply -auto-approve ) &
  pid=$!
  pids+=" ${pid}"
  echo "${pid}: Running: $project"
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

cat <<EOF > source.sh
export PROJECT_RAPID_STD_AUTO="${PROJECT_PREFIX}-defaults-${suffix}"
export PROJECT_RAPID_AP_AUTO="${PROJECT_PREFIX}-defaults-rapid-${suffix}"
export PROJECT_REGULAR_STD_AUTO="${PROJECT_PREFIX}-defaults-regular-${suffix}"
export PROJECT_REGULAR_AP_AUTO="${PROJECT_PREFIX}-defaults-private-${suffix}"
export PROJECT_RAPID_STD_MANUAL="${PROJECT_PREFIX}-defaults-private-rapid-${suffix}"
export PROJECT_RAPID_AP_MANUAL="${PROJECT_PREFIX}-defaults-private-regular-${suffix}"
EOF