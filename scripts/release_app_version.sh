#!/bin/bash

VERSION=""
NO_MERGE="0"

APP_REPO_URL="https://github.com/crusoecloud/crusoe-cloud-controller-manager.git"

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-merge)
            NO_MERGE="1"
            shift
            ;;
        *)
            VERSION="$1"
            shift
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    printf '\n\e[1;31m%s\e[0m\n' "ERROR: You must provide a semantic version to the script (eg. v1.0.0)"
    exit 1
fi

if ! git ls-remote --tags $APP_REPO_URL | sed -n "/$VERSION/p"; then
    echo "App version: '$VERSION' does not exist in '$APP_REPO_URL'."
fi

BRANCH_NAME="release-$VERSION"

if [[ "$NO_MERGE" -ne "1" ]]; then
    # Update current branch
    git fetch -p && git pull
    # Create branch
    git branch "$BRANCH_NAME"
fi

git checkout "$BRANCH_NAME"

CUR_APP_VERSION=$(yq e '.appVersion' charts/crusoe-cloud-controller-manager/Chart.yaml)
if [[ "$VERSION" == "$CUR_APP_VERSION" ]]; then
    printf '\n\e[1;32m%s\e[0m\n' "Version ${VERSION} is the same as the current app version in the chart"
    exit 0
fi

# Check for major version change
CUR_APP_MAJOR=$(echo "$CUR_APP_VERSION" | cut -d. -f1)
if [[ ! "$VERSION" =~ ^${CUR_APP_MAJOR}\.[0-9]+\.[0-9]+$ ]]; then
    printf '\n\e[1;31m%s\e[0m\n' "ERROR: App version ${VERSION} has different major version than current app version in chart: ${CUR_APP_VERSION}, manual upgrade is required"
    exit 1
fi

# Check for minor version change
CUR_CHART_VERSION=$(yq e '.version' charts/crusoe-cloud-controller-manager/Chart.yaml)
CUR_APP_MINOR=$(echo "$CUR_APP_VERSION" | cut -d. -f2)
CUR_CHART_MINOR=$(echo "$CUR_CHART_VERSION" | cut -d. -f2)
NEW_APP_MINOR=$(echo "$VERSION" | cut -d. -f2)
NEW_CHART_MINOR=$CUR_CHART_MINOR
CUR_CHART_PATCH=$(echo "$CUR_CHART_VERSION" | cut -d. -f3)
NEW_CHART_PATCH=$((CUR_CHART_PATCH+1))
if [[ "$NEW_APP_MINOR" -lt "$CUR_APP_MINOR" ]]; then
    printf '\n\e[1;31m%s\e[0m\n' "ERROR: App version ${VERSION} has lower minor version than current app version in chart: ${CUR_APP_VERSION}, downgrades are not allowed"
    exit 1
elif [[ "$NEW_APP_MINOR" -ne "$CUR_APP_MINOR" ]]; then
    printf '\n\e[1;33m%s\e[0m\n' "WARN: App version ${VERSION} has different minor version than current app version in chart: ${CUR_APP_VERSION}, continuing to update chart"
    NEW_CHART_MINOR=$((CUR_CHART_MINOR+1))
    NEW_CHART_PATCH=0
fi

# Update chart
CUR_CHART_MAJOR=$(echo "$CUR_CHART_VERSION" | cut -d. -f1)
NEW_CHART_VERSION="${CUR_CHART_MAJOR}.${NEW_CHART_MINOR}.${NEW_CHART_PATCH}"
sed -E -e "s/appVersion: \"${CUR_APP_VERSION}\"/appVersion: \"${VERSION}\"/g" -i "" charts/crusoe-cloud-controller-manager/Chart.yaml
sed -E -e "s/version: ${CUR_CHART_VERSION}/version: ${NEW_CHART_VERSION}/g" -i "" charts/crusoe-cloud-controller-manager/Chart.yaml
sed -E -e "s/tag: \"${CUR_APP_VERSION}\"/tag: \"${VERSION}\"/g" -i "" charts/crusoe-cloud-controller-manager/values.yaml

# Create MR
MR_DESC="**Release version ${VERSION}**<br><br>"
git add charts/crusoe-cloud-controller-manager/Chart.yaml charts/crusoe-cloud-controller-manager/values.yaml
git commit -m "Update chart to $VERSION"
# Push and open merge request
git push -o merge_request.create -o merge_request.title="Release $VERSION" -o merge_request.description="$MR_DESC" \
     -o merge_request.remove_source_branch -o merge_request.target="release" -u origin "${BRANCH_NAME}"
printf '\n\e[1;32m%s\e[0m\n' "Updated app version to ${VERSION}, chart version to ${NEW_CHART_VERSION}"
