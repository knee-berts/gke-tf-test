
#!/usr/bin/env bash
set -Euo pipefail

suffix=$RANDOM
unset projects
declare -t projects=(
  "${PROJECT_PREFIX}-dft-${suffix}"
  "${PROJECT_PREFIX}-dft-rapid-${suffix}"
  "${PROJECT_PREFIX}-dft-reg-${suffix}"
  "${PROJECT_PREFIX}-dft-priv-${suffix}"
  "${PROJECT_PREFIX}-dft-priv-rapid-${suffix}"
  "${PROJECT_PREFIX}-dft-priv-reg-${suffix}"
  "${PROJECT_PREFIX}-kitchsink-rapid-priv-${suffix}"
  "${PROJECT_PREFIX}-kitchsink-reg-priv-${suffix}"
  )

WORKDIR=`pwd`
pids=""
for project in ${projects[@]}; do
  DIR="tests/test-${project}"
  mkdir -p ${DIR}
  ./project-test.sh -p ${project} > ${DIR}/output.txt 2>&1 &
  pid=$!
  pids+=" ${pid}"
  echo "${pid}: Running: $project"
  cd ${WORKDIR}
done

for p in $(ps | grep "terraform apply -var" | awk -F " " '{print $1}'); do
  if wait $p; then
    echo "Terraform apply process $p running in the background."
  else
    echo "Terraform apply process $p failed. Apply aborted."
    echo "Killing any running concurrent commands."
    kill $p &> /dev/null
  fi
done

cat <<EOF >> env.sh
  export DEFAULTS_PROJECT="${PROJECT_PREFIX}-dft-${suffix}"
  export DEFAULTS_RAPID_PROJECT="${PROJECT_PREFIX}-ddft-rapid-${suffix}"
  export DEFAULTS_REGULAR_PROJECT="${PROJECT_PREFIX}-dft-reg-${suffix}"
  export DEFAULTS_PRIVATE_PROJECT="${PROJECT_PREFIX}-dft-priv-${suffix}"
  export DEFAULTS_PRIVATE_RAPID_PROJECT="${PROJECT_PREFIX}-dft-priv-rapid-${suffix}"
  export DEFAULTS_PRIVATE_REGULAR_PROJECT="${PROJECT_PREFIX}-dft-priv-reg-${suffix}"
  export KITCHEN_SINK_RAPID_PRIVATE="${PROJECT_PREFIX}-kitchsink-rapid-priv-${suffix}"
  export KITCHEN_SINK_RREGULAR_PRIVATE="${PROJECT_PREFIX}-kitchsink-reg-priv-${suffix}"
EOF