#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

argocd login --core
oc project openshift-gitops
argocd app delete shop -y
oc delete -f canary-service-mesh/application-shop-mesh.yaml

if [ ${1:-no} = "no" ]
then
    oc delete smmr -n istio-system default
    oc delete smcp -n istio-system basic
    oc delete validatingwebhookconfiguration/openshift-operators.servicemesh-resources.maistra.io
    oc delete mutatingwebhookconfiguration/openshift-operators.servicemesh-resources.maistra.io
    oc delete -n openshift-operators daemonset/istio-node
    oc delete clusterrole/istio-admin clusterrole/istio-cni clusterrolebinding/istio-cni
    oc delete clusterrole istio-view istio-edit
    oc delete clusterrole jaegers.jaegertracing.io-v1-admin jaegers.jaegertracing.io-v1-crdview jaegers.jaegertracing.io-v1-edit jaegers.jaegertracing.io-v1-view
    oc get crds -o name | grep '.*\.istio\.io' | xargs -r -n 1 oc delete
    oc get crds -o name | grep '.*\.maistra\.io' | xargs -r -n 1 oc delete
    oc get crds -o name | grep '.*\.kiali\.io' | xargs -r -n 1 oc delete
    oc delete crds jaegers.jaegertracing.io
    #oc delete svc admission-controller -n <operator-project>
    oc delete project istio-system




    oc delete project gitops

    oc delete -f canary-service-mesh/application-cluster-config.yaml

    oc delete subscription openshift-pipelines-operator-rh -n openshift-operators
    oc delete clusterserviceversion openshift-pipelines-operator-rh.v1.10.4 -n openshift-operators

    oc delete subscription -product -n openshift-distributed-tracing
    oc delete clusterserviceversion jaeger-operator.v1.42.0-5-0.1687199951.p  -n openshift-distributed-tracing

    oc delete subscription elasticsearch-operator -n openshift-operators
    oc delete clusterserviceversion elasticsearch-operator.v5.6.7 -n openshift-operators

    oc delete subscription kiali-ossm -n openshift-operators
    oc delete clusterserviceversion kiali-operator.v1.65.6  -n openshift-operators

    oc delete subscription servicemeshoperator -n openshift-operators
    oc delete clusterserviceversion servicemeshoperator.v2.4.0  -n openshift-operators


    oc delete -f gitops/gitops-operator.yaml
    oc delete subscription openshift-gitops-operator -n openshift-operators
    oc delete clusterserviceversion openshift-gitops-operator.v1.9.0 -n openshift-operators
fi



git checkout main
git branch -d canary-mesh
git push origin --delete canary-mesh


