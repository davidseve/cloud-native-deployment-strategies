#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

argocd login --core
oc project openshift-gitops
argocd app delete shop -y

oc delete project gitops

oc delete -f canary-service-mesh/application-shop-mesh.yaml

oc delete -f canary-service-mesh/application-cluster-config.yaml



oc delete -f gitops/gitops-operator.yaml
oc delete subscription tekton -n openshift-operators
oc delete clusterserviceversion openshift-pipelines-operator-rh.v1.6.3 -n openshift-operators

oc delete subscription openshift-gitops-operator -n openshift-operators
oc delete clusterserviceversion openshift-gitops-operator.v1.5.5 -n openshift-operators

git checkout main
git branch -d mesh
git push origin --delete mesh


