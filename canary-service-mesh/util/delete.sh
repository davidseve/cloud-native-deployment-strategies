#!/usr/bin/env bash

#desabilitar auto sinc argo application
#borrar service member
#borrar member roll, 
#borrar smcp
#borra cluster application
#desinstalar operadores

cd /tmp/deployment/cloud-native-deployment-strategies

argocd login --core
oc project openshift-gitops
argocd app delete shop -y

oc delete project gitops

oc delete -f canary-service-mesh/application-shop-mesh.yaml

oc delete -f canary-service-mesh/application-cluster-config.yaml

oc delete subscription openshift-pipelines-operator-rh -n openshift-operators
oc delete clusterserviceversion openshift-pipelines-operator-rh.v1.10.0 -n openshift-operators

oc delete subscription jaeger-product -n openshift-operators
oc delete clusterserviceversion jaeger-operator.v1.42.0-5-0.1687199951.p  -n openshift-operators

oc delete subscription elasticsearch-operator -n openshift-operators
oc delete clusterserviceversion elasticsearch-operator.v5.6.7 -n openshift-operators

oc delete subscription kiali-ossm -n openshift-operators
oc delete clusterserviceversion kiali-operator.v1.65.6  -n openshift-operators

oc delete subscription servicemeshoperator -n openshift-operators
oc delete clusterserviceversion servicemeshoperator.v2.4.0  -n openshift-operators

if [ ${1:-no} = "no" ]
then
    oc delete -f gitops/gitops-operator.yaml
    oc delete subscription openshift-gitops-operator -n openshift-operators
    oc delete clusterserviceversion openshift-gitops-operator.v1.5.6-0.1664915551.p  -n openshift-operators
fi


#TODO delete the other operators
git checkout main
# git branch -d mesh
# git push origin --delete mesh


