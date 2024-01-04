#!/usr/bin/env bash

#./test.sh si release no github_pat_XXXXXXXXXXXXXXX PASSWORD https://api.cluster-XX.XX.XX.opentlc.com:6443 

#token needs:  Read and Write access to code, commit statuses, and pull requests
user=user1
token=$4
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


# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Add Argo CD Git Webhook to make it faster

rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
#To work with a branch that is not main. ./test.sh ghp_JGFDSFIGJSODIJGF no helm_base
if [ ${2:-no} != "no" ]
then
    git fetch
    git switch $2
fi
git checkout -b release
git push origin release

if [ ${3:-no} = "no" ]
then
    oc apply -f gitops/gitops-operator.yaml
    waitoperatorpod gitops

    sed -i "s/changeme_token/$4/g" blue-green-pipeline-environments/application-cluster-config.yaml
    sed -i 's/changeme_user/davidseve/g' blue-green-pipeline-environments/application-cluster-config.yaml
    sed -i 's/changeme_mail/davidseve@gmail.com/g' blue-green-pipeline-environments/application-cluster-config.yaml
    sed -i 's/changeme_repository/davidseve/g' blue-green-pipeline-environments/application-cluster-config.yaml

    #To work with a branch that is not main. ./test.sh ghp_JGFDSFIGJSODIJGF no helm_base
    if [ ${2:-no} != "no" ]
    then
        sed -i "s/HEAD/$2/g" blue-green-pipeline-environments/application-cluster-config.yaml
    fi

    oc apply -f blue-green-pipeline-environments/application-cluster-config.yaml --wait=true

    #First time we install operators take logger
    if [ ${1:-no} = "no" ]
    then
        sleep 1m
    else
        sleep 2m
    fi
fi




sed -i 's/change_me/davidseve/g' blue-green-pipeline-environments/applicationset-shop-blue-green.yaml
sed -i "s/user1/$user/g" blue-green-pipeline-environments/applicationset-shop-blue-green.yaml
sed -i "s/user1/$user/g" blue-green-pipeline-environments/pipelines/run-products-stage/*
sed -i "s/user1/$user/g" blue-green-pipeline-environments/pipelines/run-products-prod/*

oc login -u $user -p $5 $6

oc apply -f blue-green-pipeline-environments/applicationset-shop-blue-green.yaml --wait=true
sleep 1m
export TOKEN=$4
export GIT_USER=davidseve
oc create secret generic github-token --from-literal=username=${GIT_USER} --from-literal=password=${TOKEN} --type "kubernetes.io/basic-auth" -n $user-continuous-deployment
oc annotate secret github-token "tekton.dev/git-0=https://github.com/davidseve" -n $user-continuous-deployment
oc secrets link pipeline github-token -n $user-continuous-deployment


cd blue-green-pipeline-environments/pipelines/run-products-stage
namespace=$user-stage
while [[ "$namespace" != "exit" ]]
do
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog

    
    oc create -f 1-pipelinerun-products-new-version.yaml -n $user-continuous-deployment
    sleep 1m
    funcPull

    oc get service products-umbrella-offline -n $namespace --output="jsonpath={.spec.selector.version}" > color
    replicas=-1
    while [ $replicas != 2 ]
    do
        sleep 5
        replicas=$(oc get deployments products-$(cat color) -n $namespace --output="jsonpath={.spec.replicas}" 2>&1)
        echo $replicas

    done

    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=offline --param LABEL=.mode --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.products[0].discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog


    oc create -f 2-pipelinerun-products-switch.yaml -n $user-continuous-deployment
    sleep 2m
    funcPull
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog

    #Rollback
    oc create -f 2-pipelinerun-products-switch-rollback.yaml -n $user-continuous-deployment
    sleep 1m
    funcPull
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.0.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog


    oc create -f 2-pipelinerun-products-switch.yaml -n $user-continuous-deployment
    sleep 2m
    funcPull
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog


    oc create -f 3-pipelinerun-products-align-offline.yaml -n $user-continuous-deployment
    sleep 1m
    funcPull

    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=online --param MODE=online --param LABEL=.mode --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.products[0].discountInfo.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=offline --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog
    tkn pipeline start pipeline-blue-green-e2e-test --param NEW_IMAGE_TAG=v1.1.1 --param MODE=online --param LABEL=.version --param APP=products --param NAMESPACE=$namespace  --param MESH=False --param JQ_PATH=.metadata --workspace name=app-source,claimName=workspace-pvc-shop-cd-e2e-tests -n $user-continuous-deployment --showlog


    if [ $namespace = "$user-stage" ]
    then
        cd ..
        cd run-products-prod
        namespace=$user-prod
    else
        namespace=exit
    fi
    
    echo $namespace
done

