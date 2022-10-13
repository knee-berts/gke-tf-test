set -Euo pipefail

unset projects
declare -t projects=(
  ${DEFAULTS_PROJECT}
  ${DEFAULTS_RAPID_PROJECT}
  ${DEFAULTS_REGULAR_PROJECT}
  ${DEFAULTS_PRIVATE_PROJECT}
  ${DEFAULTS_PRIVATE_RAPID_PROJECT}
  ${DEFAULTS_PRIVATE_REGULAR_PROJECT}
  ${KITCHEN_SINK_RAPID_PRIVATE}
  ${KITCHEN_SINK_RREGULAR_PRIVATE}
  )

for project in ${projects[@]}; do
  gcloud projects delete ${project} -q
  echo "$project was deleted."
done

echo "Done"