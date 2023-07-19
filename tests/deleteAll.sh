#!/usr/bin/env bash

echo ¡¡blue-green-pipeline!!
cd ../blue-green-pipeline/util
./delete.sh

echo ¡¡blue-green-argo-rollouts!!
cd ../../blue-green-argo-rollouts/util
./delete.sh

echo ¡¡canary-argo-rollouts!!
cd ../../canary-argo-rollouts/util
./delete.sh

echo ¡¡canary-service-mesh!!
cd ../../canary-service-mesh/util
./delete.sh

echo ¡¡canary-argo-rollouts-service-mesh!!
cd ../../canary-argo-rollouts-service-mesh/util
./delete.sh
