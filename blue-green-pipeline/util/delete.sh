#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

argocd app delete shop
argocd app delete cluster-configuration
sleep 5

oc delete project gitops

oc delete -f blue-green-pipeline/application-shop-blue-green.yaml

oc delete -f blue-green-pipeline/application-cluster-config.yaml
oc delete -f gitops/gitops-operator.yaml
oc delete subscription tekton -n openshift-operators
oc delete clusterserviceversion openshift-pipelines-operator-rh.v1.6.3 -n openshift-operators

git checkout main
git branch -d blue-green
git push origin --delete blue-green

#manual
#gitops operator