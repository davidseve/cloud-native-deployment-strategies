#!/usr/bin/env bash
rm -rf /tmp/deployment
mkdir /tmp/deployment

git checkout -b blue-green
git push origin blue-green

TODO change blue-green-pipeline/application-cluster-config.yaml

oc apply -f gitops/gitops-operator.yaml

TODO change blue-green-pipeline/application-cluster-config.yaml

oc apply -f blue-green-pipeline/application-shop-blue-green.yaml

cd blue-green-pipeline/pipelines/run-products
oc create -f 1-pipelinerun-products-new-version.yaml -n gitops

sleep?

TODO




execute new pipeline e2e test