#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies


oc delete -f canary-argo-rollouts/application-shop-canary-rollouts.yaml



git checkout main
git branch -d canary
git push origin --delete canary

#manual
#argo app argo-rollouts
#gitops operator
