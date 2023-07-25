#!/usr/bin/env bash

#./test.sh si rollouts no

# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Add Argo CD Git Webhook to make it faster

waitpodup(){
  x=1
  test=""
  while [ -z "${test}" ]
  do 
    echo "Waiting ${x} times for pod ${1} in ns ${2}" $(( x++ ))
    sleep 1 
    test=$(oc get po -n ${2} | grep ${1})
  done
}

waitoperatorpod() {
  NS=openshift-operators
  waitpodup $1 ${NS}
  oc get pods -n ${NS} | grep ${1} | awk '{print "oc wait --for condition=Ready -n '${NS}' pod/" $1 " --timeout 300s"}' | sh
}

waitjaegerpod() {
  NS=openshift-distributed-tracing
  waitpodup $1 ${NS}
  oc get pods -n ${NS} | grep ${1} | awk '{print "oc wait --for condition=Ready -n '${NS}' pod/" $1 " --timeout 300s"}' | sh
}

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
git checkout -b canary 
git push origin canary 

if [ ${3:-no} = "no" ]
then
    oc apply -f gitops/gitops-operator.yaml
    waitoperatorpod gitops

    #To work with a branch that is not main. ./test.sh no helm_base
    if [ ${2:-no} != "no" ]
    then
        sed -i "s/HEAD/$2/g" canary-argo-rollouts/application-cluster-config.yaml
    fi

    sed -i '/pipeline.enabled/{n;s/.*/        value: "true"/}' canary-argo-rollouts/application-cluster-config.yaml

    oc apply -f canary-argo-rollouts/application-cluster-config.yaml --wait=true

    waitoperatorpod pipelines
fi

sed -i 's/change_me/davidseve/g' canary-argo-rollouts/application-shop-canary-rollouts.yaml

oc apply -f canary-argo-rollouts/application-shop-canary-rollouts.yaml --wait=true
sleep 30s
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

sed -i '/products-blue/{n;n;n;n;s/.*/      tag: v1.1.1/}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts.yaml

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

tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

status=none
while [[ "$status" != "Healthy" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog

#Rollback
#this is not neccesary becase argo rollouts do the rollback because of scaleDownDelaySeconds (default 30 seconds), just to make it work I add the sleep
git revert HEAD --no-edit
sed -i '/products-blue/{n;n;n;n;n;n;n;n;n;n;n;n;n;n;n;N;N;N;N;d;}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts.yaml
sed -i '/products-blue/{n;n;n;n;n;n;n;n;n;n;n;n;n;n;n;s/.*/          - setWeight: 100/}' helm/quarkus-helm-umbrella/chart/values/values-canary-rollouts.yaml
git add .
git commit -m "delete steps for rollout"
git push origin canary

status=none
while [[ "$status" != "Healthy" ]]
do
    sleep 5
    status=$(kubectlArgo argo rollouts status products -n gitops  --watch=false)
    echo $status
done
tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=gitops  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n gitops --showlog
