#!/usr/bin/env bash
rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
git checkout -b canary 
git push origin canary 

oc apply -f gitops/gitops-operator.yaml

sleep 30s

sed -i '/pipeline.enabled/{n;s/.*/        value: "true"/}' canary-argo-rollouts/application-cluster-config.yaml
oc apply -f canary-argo-rollouts/application-cluster-config.yaml --wait=true

sleep 1m

sed -i 's/change_me/davidseve/g' canary-argo-rollouts/application-shop-canary-rollouts.yaml

oc apply -f canary-argo-rollouts/application-shop-canary-rollouts.yaml --wait=true
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

sed -i '/products-blue/{n;n;n;s/.*/    tag: v1.1.1/}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts.yaml

git add helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts.yaml
git commit -m "Change products version to v1.1.1"
git push origin canary 

status=none
while [[ "$status" != "Paused - CanaryPauseStep" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

status=none
while [[ "$status" != "Healthy" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

#Rollback
#this is not neccesary becase argo rollouts do the rollback because of scaleDownDelaySeconds (default 30 seconds), just to make it work I add the sleep
git revert HEAD --no-edit
sed -i '/products-blue/{n;n;n;n;n;n;n;n;n;n;N;N;N;N;N;N;d;}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts.yaml
git add .
git commit -m "delete steps for rollout"
git push origin canary


status=none
while [[ "$status" != "Paused - CanaryPauseStep" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
status=none
while [[ "$status" != "Healthy" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
