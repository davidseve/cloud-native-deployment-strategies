# Istio
añado operador service mesh
desde 

```
oc apply -f gitops/application-cluster-config.yaml -n openshift-gitops
```
```
oc apply -f gitops/application-shop.yaml -n openshift-gitops
```
HTTP no HTTPS

Example
watch -n 1 curl http://istio-ingressgateway-istio-system.apps.cluster-lsxh6.lsxh6.sandbox1300.opentlc.com/products

TODO


crear un helm para la config y decidir si va con istio o no. que no aparezca blue green y sea A/B o canary
crear pipelies para cambio de wight
argo rollouts
test de validacion tanto blue/green como A/B
añadir al borrar, borrar todos los operadores

Hace que shop espere para que ijecte el sidecar (no se como hacerlo por eso saco la aplicacion de cluster-config)




probocar errores y ver que pasa en grafana
