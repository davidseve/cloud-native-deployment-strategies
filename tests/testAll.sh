#!/usr/bin/env bash

echo ¡¡blue-green-pipeline!!
cd blue-green-pipeline/util
./test.sh si no no $1 #GitHub PAT
sleep 1m
cd blue-green-pipeline/util
./delete.sh

echo ¡¡blue-green-argo-rollouts!!
cd blue-green-argo-rollouts/util
./test.sh no no no
sleep 1m
cd blue-green-argo-rollouts/util
./delete.sh

echo ¡¡canary-argo-rollouts!!
cd canary-argo-rollouts/util
./test.sh no no no
sleep 1m
cd canary-argo-rollouts/util
./delete.sh

echo ¡¡canary-service-mesh!!
cd canary-service-mesh/util
./test.sh no no no $2 #Cluster Domain

cd canary-service-mesh/util
./delete.sh
