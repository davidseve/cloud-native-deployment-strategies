#!/usr/bin/env bash

#./test.sh si rollouts no github_pat_XXXXXXXXXXXXXXX

# oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
# Add Argo CD Git Webhook to make it faster

rm -rf /tmp/deployment
mkdir /tmp/deployment
cd /tmp/deployment

git clone https://github.com/davidseve/cloud-native-deployment-strategies.git
cd cloud-native-deployment-strategies

if [ ${2:-no} != "no" ]
then
    git fetch
    git switch $2
fi
git checkout -b blue-green
git push origin blue-green

if [ ${3:-no} = "no" ]
then
    oc apply -f gitops/gitops-operator.yaml
    #First time we install operators take logger
    if [ ${1:-no} = "no" ]
    then
        sleep 30s
    else
        sleep 2m
    fi
fi


sed -i "s/changeme_token/$4/g" blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_user/davidseve/g' blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_mail/davidseve@gmail.com/g' blue-green-pipeline/application-cluster-config.yaml
sed -i 's/changeme_repository/davidseve/g' blue-green-pipeline/application-cluster-config.yaml

if [ ${2:-no} != "no" ]
then
    sed -i "s/HEAD/$2/g" blue-green-pipeline/application-cluster-config.yaml
fi
oc apply -f blue-green-pipeline/application-cluster-config.yaml --wait=true

#First time we install operators take logger
if [ ${1:-no} = "no" ]
then
    sleep 2m
else
    sleep 3m
fi

sed -i 's/change_me/davidseve/g' blue-green-pipeline/application-shop-blue-green.yaml

oc apply -f blue-green-pipeline/application-shop-blue-green.yaml --wait=true


