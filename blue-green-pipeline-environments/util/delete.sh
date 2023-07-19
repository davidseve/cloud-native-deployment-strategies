#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies


oc delete -f blue-green-pipeline-environments/applicationset-shop-blue-green.yaml

if [ ${1:-no} = "no" ]
then

    oc delete -f blue-green-pipeline-environments/application-cluster-config.yaml

    currentCSV=$(oc get subscription openshift-pipelines-operator-rh -n openshift-operators -o yaml | grep currentCSV | sed 's/  currentCSV: //')
    echo $currentCSV
    oc delete subscription openshift-pipelines-operator-rh -n openshift-operators
    oc delete clusterserviceversion $currentCSV -n openshift-operators

    currentCSV=$(oc get subscription openshift-gitops-operator -n openshift-operators -o yaml | grep currentCSV | sed 's/  currentCSV: //')
    echo $currentCSV
    oc delete -f gitops/gitops-operator.yaml
    oc delete subscription openshift-gitops-operator -n openshift-operators
    oc delete clusterserviceversion $currentCSV  -n openshift-operators

    oc delete project gitops
fi

oc delete project user1-stage
oc delete project user1-prod
oc delete project user1-continuous-deployment
oc delete project user2-stage
oc delete project user2-prod
oc delete project user2-continuous-deployment

git checkout main
git branch -d release
git push origin --delete release
