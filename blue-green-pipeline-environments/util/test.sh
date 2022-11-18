#!/usr/bin/env bash


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
git checkout -b release
git push origin release

oc login  -u opentlc-mgr -p r3dh4t1! $4
oc apply -f gitops/gitops-operator.yaml

#First time we install operators take logger
if [ ${2:-no} = "no" ]
then
    sleep 30s
else
    sleep 1m
fi

#To work with a branch that is not main. ./test.sh ghp_JGFDSFIGJSODIJGF no helm_base
if [ ${3:-no} != "no" ]
then
    sed -i "s/HEAD/$3/g" blue-green-pipeline-environments/application-cluster-config.yaml
fi


oc apply -f blue-green-pipeline-environments/application-cluster-config.yaml --wait=true

#First time we install operators take logger
if [ ${2:-no} = "no" ]
then
    sleep 1m
else
    sleep 2m
fi

sed -i 's/change_me/davidseve/g' blue-green-pipeline-environments/applicationset-shop-blue-green.yaml

oc login -u user1 -p openshift $4

oc apply -f blue-green-pipeline-environments/applicationset-shop-blue-green.yaml --wait=true

export TOKEN=$1
export GIT_USER=davidseve
oc create secret generic github-token --from-literal=username=${GIT_USER} --from-literal=password=${TOKEN} --type "kubernetes.io/basic-auth" -n user1-continuous-deployment
oc annotate secret github-token "tekton.dev/git-0=https://github.com/davidseve" -n user1-continuous-deployment
oc secrets link pipeline github-token -n user1-continuous-deployment


cd blue-green-pipeline-environments/pipelines/run-products-stage
namespace=user1-stage
while [[ "$namespace" != "exit" ]]
do
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog

    
    oc create -f 1-pipelinerun-products-new-version.yaml -n user1-continuous-deployment
    sleep 90s
    funcPull

    oc get service products-umbrella-offline -n $namespace --output="jsonpath={.spec.selector.version}" > color
    replicas=-1
    while [ $replicas != 2 ]
    do
        sleep 5
        replicas=$(oc get deployments products-$(cat color) -n $namespace --output="jsonpath={.spec.replicas}" 2>&1)
        echo $replicas

    done

    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=offline --param LABEL=.mode --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.products[0].discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog


    oc create -f 2-pipelinerun-products-switch.yaml -n user1-continuous-deployment
    sleep 2m
    funcPull
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog

    #Rollback
    oc create -f 2-pipelinerun-products-switch-rollback.yaml -n user1-continuous-deployment
    sleep 90s
    funcPull
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog


    oc create -f 2-pipelinerun-products-switch.yaml -n user1-continuous-deployment
    sleep 2m
    funcPull
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog


    oc create -f 3-pipelinerun-products-align-offline.yaml -n user1-continuous-deployment
    sleep 90s
    funcPull

    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=online --param LABEL=.mode --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.products[0].discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n user1-continuous-deployment --showlog


    if [ $namespace = "user1-stage" ]
    then
        cd ..
        cd run-products-prod
        namespace=user1-prod
    else
        namespace=exit
    fi
    
    echo $namespace
done

