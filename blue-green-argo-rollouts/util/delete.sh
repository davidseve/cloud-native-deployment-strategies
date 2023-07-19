#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

oc delete project gitops

oc delete -f blue-green-argo-rollouts/application-shop-blue-green-rollouts.yaml

oc delete -f blue-green-argo-rollouts/application-cluster-config.yaml
argocd login --core
oc project openshift-gitops
argocd app delete argo-rollouts -y
argocd app delete applications-ci -y

oc delete subscription openshift-pipelines-operator-rh -n openshift-operators
oc delete clusterserviceversion openshift-pipelines-operator-rh.v1.10.4 -n openshift-operators

if [ ${1:-no} = "no" ]
then
    oc delete -f gitops/gitops-operator.yaml
    oc delete subscription openshift-gitops-operator -n openshift-operators
    oc delete clusterserviceversion openshift-gitops-operator.v1.9.1  -n openshift-operators
    # kubectl delete -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    # kubectl delete namespace argo-rollouts
fi

git checkout main
git branch -d rollouts-blue-green
git push origin --delete rollouts-blue-green

#manual
#argo app argo-rollouts
#gitops operator
