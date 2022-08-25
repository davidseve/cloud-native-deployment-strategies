#!/usr/bin/env bash

# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Add Argo CD Git Webhook to make it faster

rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
git checkout -b blue-green
git push origin blue-green

oc apply -f gitops/gitops-operator.yaml

sleep 30s

sed -i "s/changeme_token/$1/g" blue-green-pipeline-environments/applicationset-cluster-config.yaml
sed -i 's/changeme_user/davidseve/g' blue-green-pipeline-environments/applicationset-cluster-config.yaml
sed -i 's/changeme_mail/davidseve@gmail.com/g' blue-green-pipeline-environments/applicationset-cluster-config.yaml
sed -i 's/changeme_repository/davidseve/g' blue-green-pipeline-environments/applicationset-cluster-config.yaml

oc apply -f blue-green-pipeline-environments/applicationset-cluster-config.yaml --wait=true

sleep 1m

sed -i 's/change_me/davidseve/g' blue-green-pipeline-environments/applicationset-shop-blue-green.yaml

oc apply -f blue-green-pipeline-environments/applicationset-shop-blue-green.yaml --wait=true

cd blue-green-pipeline-environments/pipelines/run-products
namespace=gitops-pre
while [[ "$namespace" != "exit" ]]
do
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace --showlog

    
    oc create -f 1-pipelinerun-products-new-version.yaml -n $namespace

    oc get service products-umbrella-offline -n $namespace --output="jsonpath={.spec.selector.version}" > color
    replicas=-1
    while [ $replicas != 0 ]
    do
        sleep 5
        replicas=$(oc get deployments products-$(cat color) -n $namespace --output="jsonpath={.spec.replicas}" 2>&1)
        echo $replicas
    done
    while [ $replicas != 2 ]
    do
        sleep 5
        replicas=$(oc get deployments products-$(cat color) -n $namespace --output="jsonpath={.spec.replicas}" 2>&1)
        echo $replicas

    done

    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=offline --param LABEL=.mode --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.products[0].discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace --showlog
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace --showlog

    oc create -f 2-pipelinerun-products-switch.yaml -n $namespace
    sleep 20s
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace --showlog

    #Rollback
    oc create -f 2-pipelinerun-products-switch-rollback.yaml -n $namespace
    sleep 20s
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace --showlog


    oc create -f 2-pipelinerun-products-switch.yaml -n $namespace
    sleep 20s
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace --showlog


    oc create -f 3-pipelinerun-products-scale-down.yaml -n $namespace
    sleep 30s

    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=online --param LABEL=.mode --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.products[0].discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $namespace --showlog


    if [ $namespace = "gitops-pre" ]
    then
        namespace=gitops-prod
    else
        namespace=exit
    fi
    
    echo $namespace
done
