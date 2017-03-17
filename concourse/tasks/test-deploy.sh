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

#----------------------------

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -f "${__DIR}/pipeline.sh" ]] && source "${__DIR}/pipeline.sh" || \
    echo "No pipeline.sh found"

echo "Running retrieval of group and artifactid to download all dependencies. It might take a while..."
retrieveGroupId
retrieveArtifactId

projectGroupId=$( retrieveGroupId )
projectArtifactId=$( retrieveArtifactId )

# download app, eureka, stubrunner
downloadJar 'true' ${REPO_WITH_JARS} ${projectGroupId} ${projectArtifactId} ${PIPELINE_VERSION}
downloadJar ${REDEPLOY_INFRA} ${REPO_WITH_JARS} ${EUREKA_GROUP_ID} ${EUREKA_ARTIFACT_ID} ${EUREKA_VERSION}
downloadJar ${REDEPLOY_INFRA} ${REPO_WITH_JARS} ${STUBRUNNER_GROUP_ID} ${STUBRUNNER_ARTIFACT_ID} ${STUBRUNNER_VERSION}
# Log in to CF to start deployment
logInToCf "${REDOWNLOAD_INFRA}" "${CF_TEST_USERNAME}" "${CF_TEST_PASSWORD}" "${CF_TEST_ORG}" "${CF_TEST_SPACE}" "${CF_TEST_API_URL}"
# setup infra
deployRabbitMqToCf
deployEureka ${REDEPLOY_INFRA} "${EUREKA_ARTIFACT_ID}-${EUREKA_VERSION}" "${EUREKA_ARTIFACT_ID}" "test"
deployStubRunnerBoot ${REDEPLOY_INFRA} "${STUBRUNNER_ARTIFACT_ID}-${STUBRUNNER_VERSION}" "${REPO_WITH_JARS}" "test" "stubrunner-${projectArtifactId}"
# deploy app
deployAndRestartAppWithNameForSmokeTests ${projectArtifactId} "${projectArtifactId}-${PIPELINE_VERSION}"
propagatePropertiesForTests ${projectArtifactId}

