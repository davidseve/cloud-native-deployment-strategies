#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

oc login  -u opentlc-mgr -p r3dh4t1! $4


oc delete -f blue-green-pipeline-environments/applicationset-shop-blue-green.yaml

oc delete -f blue-green-pipeline-environments/application-cluster-config.yaml


oc delete subscription tekton -n openshift-operators
oc delete clusterserviceversion openshift-pipelines-operator-rh.v1.6.4 -n openshift-operators

# oc delete -f gitops/gitops-operator.yaml
# oc delete subscription openshift-gitops-operator -n openshift-operators
# oc delete clusterserviceversion openshift-gitops-operator.v1.6.2 -n openshift-operators

oc delete project gitops
oc delete project user1-stage
oc delete project user1-prod
oc delete project user1-continuous-delivery

git checkout main
git branch -d release
git push origin --delete release
