
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
  "${PROJECT_PREFIX}-dft-np-kitchsink-${suffix}"
  "${PROJECT_PREFIX}-dft-np-${suffix}"
  "${PROJECT_PREFIX}-dft-np-reg-${suffix}"
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
echo "Check the output.txt file in the tests directory for each pattern to see progress."
