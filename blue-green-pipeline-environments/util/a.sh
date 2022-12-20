#!/usr/bin/env bash

user=user11
token=$1
funcPull()
{
    pull_number=$(curl -H "Accept: application/vnd.github+json"   -H "Authorization: Bearer $token"   https://api.github.com/repos/davidseve/cloud-native-deployment-strategies/pulls | jq -r '.[0].number')
    curl \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $token" \
    https://api.github.com/repos/davidseve/cloud-native-deployment-strategies/pulls/$pull_number/merge \
    -d '{"commit_title":"Expand enum","commit_message":"Add a new value to the merge_method enum"}'
}

# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Add Argo CD Git Webhook to make it faster

rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
#To work with a branch that is not main. ./test.sh ghp_JGFDSFIGJSODIJGF no helm_base
if [ ${3:-no} != "no" ]
then
    git checkout $3
fi
git checkout -b release7










sed -i 's/change_me/davidseve/g' blue-green-pipeline-environments/applicationset-shop-blue-green.yaml
sed -i "s/user1/$user/g" blue-green-pipeline-environments/applicationset-shop-blue-green.yaml
sed -i "s/user1/$user/g" blue-green-pipeline-environments/pipelines/run-products-prod/*
cat blue-green-pipeline-environments/pipelines/run-products-prod/1-pipelinerun-products-new-version.yaml
