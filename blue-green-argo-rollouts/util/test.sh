#!/usr/bin/env bash
rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
git checkout -b rollouts
git push origin rollouts

oc apply -f gitops/gitops-operator.yaml

sleep 30s

oc apply -f blue-green-argo-rollouts/application-cluster-config.yaml --wait=true

sleep 1m

sed -i 's/change_me/davidseve/g' blue-green-argo-rollouts/application-shop-blue-green-rollouts.yaml

oc apply -f blue-green-argo-rollouts/application-shop-blue-green-rollouts.yaml --wait=true
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

sed -i '/products-blue/{n;n;n;s/.*/    tag: v1.1.1/}' helm/quarkus-helm-umbrella/chart/values/values-rollouts.yaml

git add helm/quarkus-helm-umbrella/chart/values/values-rollouts.yaml
git commit -m "Change products version to v1.1.1"
git push origin rollouts

status=none
while [[ "$status" != "Paused - BlueGreenPause" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

oc project gitops
kubectlArgo argo rollouts promote products -n gitops

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
