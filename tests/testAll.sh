#!/usr/bin/env bash

#./testAll.sh si no github_pat_ rollouts.sandbox61.opentlc.com

echo $1 #fist installation
echo $2 # github branch
echo $3 # github token
echo $4 #OCP domain
echo ¡¡blue-green-pipeline!!
cd ../blue-green-pipeline/util

# ./test.sh $1 $2 no $3
# sleep 1m
# echo ¡¡Fin blue-green-pipeline!!
# cd ../../blue-green-pipeline/util
# ./delete.sh

# sleep 30s
# echo ¡¡blue-green-argo-rollouts!!
# cd ../../blue-green-argo-rollouts/util
# ./test.sh no $2 no
# sleep 1m
# echo ¡¡Fin blue-green-argo-rollouts!!
# cd ../../blue-green-argo-rollouts/util
# ./delete.sh

# sleep 30s
# echo ¡¡canary-argo-rollouts!!
# cd ../../canary-argo-rollouts/util
# ./test.sh no $2 no
# sleep 1m
# echo ¡¡Fin canary-argo-rollouts!!
# cd ../../canary-argo-rollouts/util
# ./delete.sh

sleep 30s
echo ¡¡canary-service-mesh!!
cd ../../canary-service-mesh/util
./test.sh no $2 no $4
sleep 1m
echo ¡¡Fin canary-service-mesh!!
cd ../../canary-service-mesh/util
./delete.sh

sleep 1m
echo ¡¡canary-argo-rollouts-service-mesh!!
cd ../../canary-argo-rollouts-service-mesh/util
./test.sh no $2 no $4
sleep 1m
echo ¡¡Fin canary-argo-rollouts-service-mesh!!
cd ../../canary-argo-rollouts-service-mesh/util
./delete.sh
