#!/usr/bin/env bash

#./test.sh no f/mesh-rllouts no rollouts.sandbox2653.opentlc.com

# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Add Argo CD Git Webhook to make it faster

rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
#To work with a branch that is not main. ./test.sh no helm_base
if [ ${2:-no} != "no" ]
then
    git fetch
    git switch $2
fi
git checkout -b rollouts-mesh 
git push origin rollouts-mesh 

if [ ${3:-no} = "no" ]
then
    oc apply -f gitops/gitops-operator.yaml
    #First time we install operators take logger
    if [ ${1:-no} = "no" ]
    then
        sleep 30s
    else
        sleep 2m
    fi

    #To work with a branch that is not main. ./test.sh no helm_base no rollouts.sandbox2229.opentlc.com
    if [ ${2:-no} != "no" ]
    then
        sed -i "s/HEAD/$2/g" canary-argo-rollouts-service-mesh/application-cluster-config.yaml
    fi

    sed -i '/pipeline.enabled/{n;s/.*/        value: "true"/}' canary-argo-rollouts-service-mesh/application-cluster-config.yaml

    oc apply -f canary-argo-rollouts-service-mesh/application-cluster-config.yaml --wait=true
    #First time we install operators take logger
    if [ ${1:-no} = "no" ]
    then
        sleep 2m
    else
        sleep 4m
    fi
fi

sed -i 's/change_me/davidseve/g' canary-argo-rollouts-service-mesh/application-shop-canary-rollouts-mesh.yaml
sed -i "s/change_domain/$4/g" canary-argo-rollouts-service-mesh/application-shop-canary-rollouts-mesh.yaml

oc apply -f canary-argo-rollouts-service-mesh/application-shop-canary-rollouts-mesh.yaml --wait=true
sleep 30s
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=true --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

sed -i '/products-blue/{n;n;n;n;s/.*/      tag: v1.1.1/}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts-mesh.yaml

git add helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts-mesh.yaml
git commit -m "Change products version to v1.1.1"
git push origin rollouts-mesh 

status=none
while [[ "$status" != "Paused - CanaryPauseStep" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param MESH=true --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

status=none
while [[ "$status" != "Healthy" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param MESH=true --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

#Rollback
#this is not neccesary becase argo rollouts do the rollback because of scaleDownDelaySeconds (default 30 seconds), just to make it work I add the sleep
git revert HEAD --no-edit
sed -i '/products-blue/{n;n;n;n;n;n;n;n;n;n;n;n;n;n;n;N;N;N;N;d;}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts-mesh.yaml
sed -i '/products-blue/{n;n;n;n;n;n;n;n;n;n;n;n;n;n;n;s/.*/          - setWeight: 100/}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts-mesh.yaml
git add .
git commit -m "delete steps for rollout"
git push origin rollouts-mesh

status=none
while [[ "$status" != "Healthy" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=true --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
