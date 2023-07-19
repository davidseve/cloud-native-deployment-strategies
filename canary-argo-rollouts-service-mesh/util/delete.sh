#!/usr/bin/env bash

cd /tmp/deployment/cloud-native-deployment-strategies

argocd login --core
oc project openshift-gitops
argocd app delete shop -y
oc delete -f canary-argo-rollouts-service-mesh/application-shop-canary-rollouts-mesh.yaml

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

    oc delete -f canary-argo-rollouts-service-mesh/application-cluster-config.yaml

    currentCSV=$(oc get subscription openshift-pipelines-operator-rh -n openshift-operators -o yaml | grep currentCSV | sed 's/  currentCSV: //')
    echo $currentCSV
    oc delete subscription openshift-pipelines-operator-rh -n openshift-operators
    oc delete clusterserviceversion $currentCSV -n openshift-operators

    currentCSV=$(oc get subscription jaeger-product -n openshift-distributed-tracing -o yaml | grep currentCSV | sed 's/  currentCSV: //')
    echo $currentCSV
    oc delete subscription jaeger-product -n openshift-distributed-tracing
    oc delete clusterserviceversion $currentCSV -n openshift-distributed-tracing

    currentCSV=$(oc get subscription elasticsearch-operator -n openshift-operators -o yaml | grep currentCSV | sed 's/  currentCSV: //')
    echo $currentCSV
    oc delete subscription elasticsearch-operator -n openshift-operators
    oc delete clusterserviceversion $currentCSV  -n openshift-operators

    currentCSV=$(oc get subscription kiali-ossm -n openshift-operators -o yaml | grep currentCSV | sed 's/  currentCSV: //')
    echo $currentCSV
    oc delete subscription kiali-ossm -n openshift-operators
    oc delete clusterserviceversion $currentCSV  -n openshift-operators

    currentCSV=$(oc get subscription servicemeshoperator -n openshift-operators -o yaml | grep currentCSV | sed 's/  currentCSV: //')
    echo $currentCSV
    oc delete subscription servicemeshoperator -n openshift-operators
    oc delete clusterserviceversion $currentCSV   -n openshift-operators


    currentCSV=$(oc get subscription openshift-gitops-operator -n openshift-operators -o yaml | grep currentCSV | sed 's/  currentCSV: //')
    echo $currentCSV
    oc delete -f gitops/gitops-operator.yaml
    oc delete subscription openshift-gitops-operator -n openshift-operators
    oc delete clusterserviceversion $currentCSV  -n openshift-operators

    oc delete project argo-rollouts

    oc delete project gitops
fi



git checkout main
git branch -d rollouts-mesh
git push origin --delete rollouts-mesh


