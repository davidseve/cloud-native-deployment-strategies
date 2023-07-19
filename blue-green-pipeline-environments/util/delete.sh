#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

oc delete project gitops

oc delete -f blue-green-pipeline-environments/applicationset-shop-blue-green.yaml

oc delete -f blue-green-pipeline-environments/application-cluster-config.yaml

oc delete subscription openshift-pipelines-operator-rh -n openshift-operators
oc delete clusterserviceversion openshift-pipelines-operator-rh.v1.10.4 -n openshift-operators

if [ ${1:-no} = "no" ]
then
    oc delete -f gitops/gitops-operator.yaml
    oc delete subscription openshift-gitops-operator -n openshift-operators
    oc delete clusterserviceversion openshift-gitops-operator.v1.9.1  -n openshift-operators
fi

oc delete project gitops
oc delete project user1-stage
oc delete project user1-prod
oc delete project user1-continuous-deployment
oc delete project user2-stage
oc delete project user2-prod
oc delete project user2-continuous-deployment

git checkout main
git branch -d release
git push origin --delete release
