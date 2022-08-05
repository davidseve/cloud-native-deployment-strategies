#!/usr/bin/env bash
rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
git checkout -b blue-green
git push origin blue-green

oc apply -f gitops/gitops-operator.yaml

sleep 30s

sed -i "s/changeme_token/$1/g" blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_user/davidseve/g' blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_mail/davidseve@gmail.com/g' blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_repository/davidseve/g' blue-green-pipeline/application-cluster-config.yaml

oc apply -f blue-green-pipeline/application-cluster-config.yaml --wait=true

sleep 1m

sed -i 's/change_me/davidseve/g' blue-green-pipeline/application-shop-blue-green.yaml

oc apply -f blue-green-pipeline/application-shop-blue-green.yaml --wait=true
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog

cd blue-green-pipeline/pipelines/run-products
oc create -f 1-pipelinerun-products-new-version.yaml -n gitops
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=offline --param LABEL=.mode --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.products.discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog

oc create -f 2-pipelinerun-products-switch.yaml -n gitops
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog


oc create -f 2-pipelinerun-products-switch-rollback.yaml -n gitops
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog


oc create -f 2-pipelinerun-products-switch.yaml -n gitops
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog


oc create -f 3-pipelinerun-products-scale-down.yaml -n gitops

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=online --param LABEL=.mode --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.products.discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-new-version -n gitops --showlog


