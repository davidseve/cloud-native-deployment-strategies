#!/usr/bin/env bash

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
git checkout -b blue-green
git push origin blue-green

# oc apply -f gitops/gitops-operator.yaml

# #First time we install operators take logger
# if [ ${2:-no} = "no" ]
# then
#     sleep 30s
# else
#     sleep 1m
# fi


sed -i "s/changeme_token/$1/g" blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_user/davidseve/g' blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_mail/davidseve@gmail.com/g' blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_repository/davidseve/g' blue-green-pipeline/application-cluster-config.yaml
#To work with a branch that is not main. ./test.sh ghp_JGFDSFIGJSODIJGF no helm_base
if [ ${3:-no} != "no" ]
then
    sed -i "s/HEAD/$3/g" blue-green-pipeline/application-cluster-config.yaml
fi
oc apply -f blue-green-pipeline/application-cluster-config.yaml --wait=true

#First time we install operators take logger
if [ ${2:-no} = "no" ]
then
    sleep 1m
else
    sleep 2m
fi

sed -i 's/change_me/davidseve/g' blue-green-pipeline/application-shop-blue-green.yaml

oc apply -f blue-green-pipeline/application-shop-blue-green.yaml --wait=true
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

cd blue-green-pipeline/pipelines/run-products
oc create -f 1-pipelinerun-products-new-version.yaml -n gitops

oc get service products-umbrella-offline -n gitops --output="jsonpath={.spec.selector.version}" > color
replicas=-1
while [ $replicas != 0 ]
do
    sleep 5
    replicas=$(oc get deployments products-$(cat color) -n gitops --output="jsonpath={.spec.replicas}" 2>&1)
    echo $replicas
done
while [ $replicas != 2 ]
do
    sleep 5
    replicas=$(oc get deployments products-$(cat color) -n gitops --output="jsonpath={.spec.replicas}" 2>&1)
    echo $replicas

done

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=offline --param LABEL=.mode --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.products[0].discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

oc create -f 2-pipelinerun-products-switch.yaml -n gitops
sleep 20s
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

#Rollback
oc create -f 2-pipelinerun-products-switch-rollback.yaml -n gitops
sleep 20s
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog


oc create -f 2-pipelinerun-products-switch.yaml -n gitops
sleep 20s
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog


oc create -f 3-pipelinerun-products-scale-down.yaml -n gitops
sleep 30s

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=online --param LABEL=.mode --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.products[0].discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog


