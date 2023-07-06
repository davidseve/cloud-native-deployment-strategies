#!/usr/bin/env bash

#./test.sh si rollouts no rollouts.sandbox2653.opentlc.com

# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Add Argo CD Git Webhook to make it faster

rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
#To work with a branch that is not main. ./test.sh no helm_base
if [ ${2:-no} != "no" ]
then
    git fetch
    git switch $2
fi
git checkout -b canary-mesh 
git push origin canary-mesh 

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
        sed -i "s/HEAD/$2/g" canary-service-mesh/application-cluster-config.yaml
    fi

    sed -i '/pipeline.enabled/{n;s/.*/        value: "true"/}' canary-service-mesh/application-cluster-config.yaml

    oc apply -f canary-service-mesh/application-cluster-config.yaml --wait=true
    #First time we install operators take logger
    if [ ${1:-no} = "no" ]
    then
        sleep 2m
    else
        sleep 4m
    fi
fi


sed -i 's/change_me/davidseve/g' canary-service-mesh/application-shop-mesh.yaml
sed -i "s/change_domain/$4/g" canary-service-mesh/application-shop-mesh.yaml

oc apply -f canary-service-mesh/application-shop-mesh.yaml --wait=true
sleep 30
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=true --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

#Deploy products v1.1.1 with 10% traffic
sed -i '/    productsblueWeight: 100/{s/.*/    productsblueWeight: 90/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/    productsgreenWeight: 0/{s/.*/    productsgreenWeight: 10/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/products-green:/{n;n;s/.*/    replicaCount: 1/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml

git add helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
git commit -m "Deploy products v1.1.1 with 10% traffic"
git push origin canary-mesh 
sleep 30
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=true --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=true --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

#Deploy products v1.1.1 with 50% traffic
sed -i '/    productsblueWeight: 90/{s/.*/    productsblueWeight: 50/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/    productsgreenWeight: 10/{s/.*/    productsgreenWeight: 50/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/products-green:/{n;n;s/.*/    replicaCount: 2/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/products-blue:/{n;n;s/.*/    replicaCount: 2/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml

git add helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
git commit -m "Deploy products v1.1.1 with 50% traffic"
git push origin canary-mesh 
sleep 30
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=true --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=true --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

#Delete product v1.0.1
sed -i '/  products-blue: true/{s/.*/  products-blue: false/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/    productsblueWeight: 50/{s/.*/    productsblueWeight: 0/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/    productsgreenWeight: 50/{s/.*/    productsgreenWeight: 100/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/products-green:/{n;n;s/.*/    replicaCount: 4/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
sed -i '/products-blue:/{n;n;s/.*/    replicaCount: 0/}' helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml

git add helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml
git commit -m "Delete product v1.0.1"
git push origin canary-mesh 
sleep 30
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param JQ_PATH=.metadata --param MESH=true --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

