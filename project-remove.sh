set -Euo pipefail

for project in $(gcloud projects list --filter 'parent.id=${FOLDER_ID} AND parent.type=folder AND name~${PROJECT_PREFIX}')
do
   gcloud projects delete ${project} -q
done

echo "Done"