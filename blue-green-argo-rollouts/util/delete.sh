#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

oc delete project gitops

oc delete -f blue-green-argo-rollouts/application-shop-blue-green-rollouts.yaml

oc delete -f blue-green-argo-rollouts/application-cluster-config.yaml
oc delete -f gitops/gitops-operator.yaml
oc delete subscription tekton -n openshift-operators
oc delete clusterserviceversion openshift-pipelines-operator-rh.v1.6.3 -n openshift-operators

oc delete subscription openshift-gitops-operator -n openshift-operators
oc delete clusterserviceversion openshift-gitops-operator.v1.5.5 -n openshift-operators

git checkout main
git branch -d rollouts
git push origin --delete rollouts

#manual
#argo app argo-rollouts
#gitops operator
