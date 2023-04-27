#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

argocd login --core
oc project openshift-gitops
argocd app delete argo-rollouts -y
argocd app delete shop -y

oc delete project gitops

oc delete -f canary-argo-rollouts/application-shop-canary-rollouts.yaml

oc delete -f canary-argo-rollouts/application-cluster-config.yaml



if [ ${1:-no} = "no" ]
then
    oc delete -f gitops/gitops-operator.yaml
    oc delete subscription openshift-gitops-operator -n openshift-operators
    oc delete clusterserviceversion openshift-gitops-operator.v1.5.6-0.1664915551.p  -n openshift-operators

    kubectl delete -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    kubectl delete namespace argo-rollouts
fi

oc delete subscription openshift-gitops-operator -n openshift-operators
oc delete clusterserviceversion openshift-gitops-operator.v1.5.6-0.1664915551.p  -n openshift-operators

git checkout main
git branch -d canary
git push origin --delete canary


