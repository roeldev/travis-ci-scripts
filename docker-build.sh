#!/bin/bash

# capitalized vars are set outside and/or to be used outside this script

cwd=$( pwd )
dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# export vars from cli arguments
for var in "$@"
do
    export $( echo "$var" | xargs )
done

function read-travis-yml {
    cat "${cwd}/.travis.yml" \
    | grep "$1=" \
    | cut -d "=" -f 2
}

function get-github-description {
    curl -fLs --retry 5 --url ${githubApiRepoDetails} \
    | grep "description" \
    | cut -d ":" -f 2 \
    | cut -d '"' -f 2
}

function get-github-latest {
    curl -fLs --retry 5 --url ${githubApiLatestRelease} \
    | grep "tag_name" \
    | cut -d ":" -f 2 \
    | cut -d '"' -f 2
}

function add-tag {
    IMAGE_TAG=$1
    tag=$( eval "echo -e \"$imageNameTemplate\"" )

    # return on empty tag
    if [[ "${tag: -1}" = : ]]; then exit 0; fi
    # remove last char if it is a '-' (dash)
    if [[ "${tag: -1}" = - ]]; then tag="${tag::-1}"; fi

    echo Tag ${release} as ${tag}
    docker tag ${release} ${tag}
}

# extract vars from .travis.yml when they are not set
export MAINTAINER=${MAINTAINER:=$( read-travis-yml "MAINTAINER" )}
export GITHUB_REPO=${GITHUB_REPO:=$( read-travis-yml "GITHUB_REPO" )}
export DOCKER_REPO=${DOCKER_REPO:=$( read-travis-yml "DOCKER_REPO" )}

githubApiRepoDetails="https://api.github.com/repos/${GITHUB_REPO}"
githubApiLatestRelease="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

echo ${githubApiRepoDetails}
echo ${githubApiLatestRelease}

# get description from github when not set
export DESCRIPTION=${DESCRIPTION:=$( get-github-description )}

# other build/version related vars
export BUILD_DATE=$( date -u +"%Y-%m-%dT%H:%M:%SZ" )
export GIT_REF=$( git rev-parse --short HEAD )

isVersionRelease=false
isLatestRelease=false

# set image tag according to branch/tag
export IMAGE_TAG=experimental
# new version release
if [[ "${TRAVIS_BRANCH}" == "${TRAVIS_TAG}" ]]
then
    IMAGE_TAG=${TRAVIS_TAG}
    isVersionRelease=true

    latestVersion="$( get-github-latest )"
    echo Latest version from GitHub: ${latestVersion}

    if [[ "${TRAVIS_TAG}" == "${latestVersion}" ]]
    then
        isLatestRelease=true
    fi
fi

# use the first "image:" property as template for the image names
imageNameTemplate=$( cat "${cwd}/docker-compose.yml" | grep "image:" -m 1 | cut -d ':' -f 2- )
release=$( eval "echo -e \"$imageNameTemplate\"" )

echo Building Docker image ${release}...
echo
echo "Maintainer:       ${MAINTAINER}"
echo "Description:      ${DESCRIPTION}"
echo "GitHub repo:      ${GITHUB_REPO}"
echo "Docker Hub repo:  ${DOCKER_REPO}"
echo "Build date:       ${BUILD_DATE}"
echo "Git commit ref:   ${GIT_REF}"
echo "Image tag:        ${IMAGE_TAG}"
echo "Tag as version:   ${isVersionRelease}"
echo "Tag as latest:    ${isLatestRelease}"
echo

docker-compose \
    --file "${dir}/docker-compose-base.yml" \
    --file "${cwd}/docker-compose.yml" \
    --project-name travis \
    --project-directory "${cwd}" \
    build travis

if ${isVersionRelease}
then
    add-tag "$( echo "${TRAVIS_TAG}" | cut -d '.' -f 1-2 )"
    add-tag "$( echo "${TRAVIS_TAG}" | cut -d '.' -f 1 )"
fi

if ${isLatestRelease}
then
    add-tag "latest"
    add-tag ""
fi
