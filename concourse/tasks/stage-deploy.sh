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

#---------------------------------

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -f "${__DIR}/pipeline.sh" ]] && source "${__DIR}/pipeline.sh" || \
    echo "No pipeline.sh found"

echo "Retrieving group and artifact id - it can take a while..."
projectGroupId=$( retrieveGroupId )
projectArtifactId=$( retrieveArtifactId )

# download app, eureka
downloadJar 'true' ${REPO_WITH_JARS} ${projectGroupId} ${projectArtifactId} ${PIPELINE_VERSION}
downloadJar ${REDEPLOY_INFRA} ${REPO_WITH_JARS} ${EUREKA_GROUP_ID} ${EUREKA_ARTIFACT_ID} ${EUREKA_VERSION}
# Log in to CF to start deployment
logInToCf "${REDOWNLOAD_INFRA}" "${CF_STAGE_USERNAME}" "${CF_STAGE_PASSWORD}" "${CF_STAGE_ORG}" "${CF_STAGE_SPACE}" "${CF_STAGE_API_URL}"
# setup infra
deployRabbitMqToCf
deployEureka ${REDEPLOY_INFRA} "${EUREKA_ARTIFACT_ID}-${EUREKA_VERSION}" "${EUREKA_ARTIFACT_ID}" "stage"
# deploy app
deployAndRestartAppWithName ${projectArtifactId} "${projectArtifactId}-${PIPELINE_VERSION}" "stage"
propagatePropertiesForTests ${projectArtifactId}
