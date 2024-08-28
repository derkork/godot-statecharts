REPO_ID=$(curl https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} | jq --raw-output '.id')
echo "Repo ID is ${REPO_ID}"
BASEURL=https://${CIRCLE_BUILD_NUM}-${REPO_ID}-gh.circle-artifacts.com/0/${CIRCLE_PROJECT_REPONAME}
sed -i "26 s,.*,baseurl: $BASEURL,g" "_config.yml"
