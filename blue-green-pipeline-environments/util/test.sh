#!/usr/bin/env bash

# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Add Argo CD Git Webhook to make it faster

rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies
git checkout -b blue-green
git push origin blue-green

oc apply -f gitops/gitops-operator.yaml

sleep 30s

sed -i "s/changeme_token/$1/g" blue-green-pipeline-environments/application-cluster-config.yaml
sed -i 's/changeme_user/davidseve/g' blue-green-pipeline-environments/application-cluster-config.yaml
sed -i 's/changeme_mail/davidseve@gmail.com/g' blue-green-pipeline-environments/application-cluster-config.yaml
sed -i 's/changeme_repository/davidseve/g' blue-green-pipeline-environments/application-cluster-config.yaml

oc apply -f blue-green-pipeline-environments/application-cluster-config.yaml --wait=true

sleep 1m

sed -i 's/change_me/davidseve/g' blue-green-pipeline-environments/application-shop-blue-green.yaml

oc apply -f blue-green-pipeline-environments/application-shop-blue-green.yaml --wait=true

./test-envs.sh gitops-pre
./test-envs.sh gitops-prod