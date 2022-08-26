#!/usr/bin/env bash
rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
git checkout -b mesh 
git push origin mesh 

oc apply -f gitops/gitops-operator.yaml

#First time we install operators take logger
if [ ${2:-no} = "no" ]
then
    sleep 30s
else
    sleep 1m
fi

sed -i '/pipeline.enabled/{n;s/.*/        value: "true"/}' canary-service-mesh/application-cluster-config.yaml
oc apply -f canary-service-mesh/application-cluster-config.yaml --wait=true

#First time we install operators take logger
if [ ${2:-no} = "no" ]
then
    sleep 2m
else
    sleep 4m
fi

sed -i 's/change_me/davidseve/g' canary-service-mesh/application-shop-mesh.yaml

oc apply -f canary-service-mesh/application-shop-mesh.yaml --wait=true
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=True --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

sed -i '/products-green/{n;n;n;n;s/.*/      tag: v1.1.1/}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts.yaml

git add helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts.yaml
git commit -m "Change products version to v1.1.1"
git push origin mesh 

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=True --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

##hasta aqui
