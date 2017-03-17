#!/bin/bash

set -o errexit

export ROOT_FOLDER=$( pwd )
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export VERSION_RESOURCE=version
export OUTPUT_RESOURCE=out

echo "Root folder is [${ROOT_FOLDER}]"
echo "Repo resource folder is [${REPO_RESOURCE}]"
echo "Tools resource folder is [${TOOLS_RESOURCE}]"
echo "Version resource folder is [${VERSION_RESOURCE}]"

source ${ROOT_FOLDER}/${TOOLS_RESOURCE}/concourse/tasks/pipeline.sh

echo "Deploying the built application on test environment"
cd ${ROOT_FOLDER}/${REPO_RESOURCE}

#----------------------

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -f "${__DIR}/pipeline.sh" ]] && source "${__DIR}/pipeline.sh" || \
    echo "No pipeline.sh found"

projectArtifactId=$( retrieveArtifactId )

# Log in to CF to start deployment
logInToCf "${REDOWNLOAD_INFRA}" "${CF_PROD_USERNAME}" "${CF_PROD_PASSWORD}" "${CF_PROD_ORG}" "${CF_PROD_SPACE}" "${CF_PROD_API_URL}"

# Finish the blue green deployment
deleteTheOldApplicationIfPresent "${projectArtifactId}"

