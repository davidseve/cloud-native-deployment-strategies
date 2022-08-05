#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

oc delete project gitops

oc delete -f blue-green-argo-rollouts/application-shop-blue-green-rollouts.yaml

oc delete -f blue-green-argo-rollouts/application-cluster-config.yaml
oc delete -f gitops/gitops-operator.yaml

git checkout main
git branch -d rollouts
git push origin --delete rollouts

