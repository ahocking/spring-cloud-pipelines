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

source ./pipeline.sh

echo "Deploying the built application on prod environment"
cd ${ROOT_FOLDER}/${REPO_RESOURCE}

#--------------------------
__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -f "${__DIR}/pipeline.sh" ]] && source "${__DIR}/pipeline.sh" || \
    echo "No pipeline.sh found"

projectGroupId=$( retrieveGroupId )
projectArtifactId=$( retrieveArtifactId )

# download app
downloadJar 'true' ${REPO_WITH_JARS} ${projectGroupId} ${projectArtifactId} ${PIPELINE_VERSION}
# Log in to CF to start deployment
logInToCf "${REDOWNLOAD_INFRA}" "${CF_PROD_USERNAME}" "${CF_PROD_PASSWORD}" "${CF_PROD_ORG}" "${CF_PROD_SPACE}" "${CF_PROD_API_URL}"

# deploying rabbitmq
# TODO: most likely rabbitmq and eureka would be there on production; this remains for demo purposes
deployRabbitMqToCf
downloadJar ${REDEPLOY_INFRA} ${REPO_WITH_JARS} ${EUREKA_GROUP_ID} ${EUREKA_ARTIFACT_ID} ${EUREKA_VERSION}
deployEureka ${REDEPLOY_INFRA} "${EUREKA_ARTIFACT_ID}-${EUREKA_VERSION}" "${EUREKA_ARTIFACT_ID}" "prod"

# deploy app
renameTheOldApplicationIfPresent "${projectArtifactId}"
deployAndRestartAppWithName "${projectArtifactId}" "${projectArtifactId}-${PIPELINE_VERSION}" "prod"

#---------------------------

echo "Tagging the project with prod tag"
echo "prod/${PIPELINE_VERSION}" > ${ROOT_FOLDER}/${REPO_RESOURCE}/tag
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE}/. ${ROOT_FOLDER}/${OUTPUT_RESOURCE}/
