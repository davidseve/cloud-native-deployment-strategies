# Istio
añado operador service mesh
desde 
```
oc apply -f gitops/application-cluster-config.yaml -n openshift-gitops
```
HTTP no HTTPS

http://istio-ingressgateway-istio-system.apps.cluster-qcgfc.qcgfc.sandbox596.opentlc.com/products

watch -n 1 curl http://istio-ingressgateway-istio-system.apps.cluster-qcgfc.qcgfc.sandbox596.opentlc.com/products



TODO
Hace que shop espere para que ijecte el sidecar
mira grafana como ver el estado de los micros
crear un helm para la config y decidir si va con istio o no. que no aparezca blue green y sea A/B o canary
crear pipelies para cambio de wight
argo rollouts
test de validacion tanto blue/green como A/B
añadir al borrar, borrar todos los operadores




probocar errores y ver que pasa en grafana
