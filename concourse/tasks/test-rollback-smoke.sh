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

echo "Testing the rolled back built application on test environment"
cd ${ROOT_FOLDER}/${REPO_RESOURCE}

prepareForSmokeTests "${REDOWNLOAD_INFRA}" "${CF_TEST_USERNAME}" "${CF_TEST_PASSWORD}" "${CF_TEST_ORG}" "${CF_TEST_SPACE}" "${CF_TEST_API_URL}"

echo "Resolving latest prod tag"
LATEST_PROD_TAG=$( findLatestProdTag )

echo "Retrieved application and stub runner urls"
if [[ -z "${LATEST_PROD_TAG}" || "${LATEST_PROD_TAG}" == "master" ]]; then
    echo "No prod release took place - skipping this step"
else
    git checkout "${LATEST_PROD_TAG}"


    #-----------------------------------
    __DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    [[ -f "${__DIR}/pipeline.sh" ]] && source "${__DIR}/pipeline.sh" || \
        echo "No pipeline.sh found"

    echo "Application URL [${APPLICATION_URL}]"
    echo "StubRunner URL [${STUBRUNNER_URL}]"
    echo "Latest production tag [${LATEST_PROD_TAG}]"

    if [[ -z "${LATEST_PROD_TAG}" || "${LATEST_PROD_TAG}" == "master" ]]; then
        echo "No prod release took place - skipping this step"
    else
        LATEST_PROD_VERSION=$( extractVersionFromProdTag ${LATEST_PROD_TAG} )
        echo "Last prod version equals ${LATEST_PROD_VERSION}"
        runSmokeTests ${APPLICATION_URL} ${STUBRUNNER_URL}
    fi
    #-------------------------------

fi
