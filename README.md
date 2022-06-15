# Cloud Native Blue/Green

## Blue/Green Deployment

Blue green deployment is an application release model that transfers user traffic from a previous version of an app or microservice to a nearly identical new release, both of which are running in production.
The old version can be called the blue environment while the new version can be known as the green environment. Once production traffic is fully transferred from blue to green, blue can standby in case of rollback or pulled from production and updated to become the template upon which the next update is made.

Advantages:
- Minimize downtime
- Rapid way to rollback 
- Smoke testing

Disadvantages:
- Doubling of total resources
- Backwards compatibility


![Shop Application](images/blue-green.png)

## Shop application

We are going to use very simple applications to test Blue/Green deployment. We have create two Quarkus applications `Products` and `Discounts`

![Shop Application](images/Shop.png)

`Products` expose an API with a list of products and call `Discounts` to get the discounts of the products

## Shop Blue/Green

To achieve blue/green deployment with `Cloud Native` applications we have design this architecture.

![Shop Blue/Green](images/Shop-blue-green.png)

OpenShift Components - Online
- Routes and Services declared with suffix -online
- Routes mapped only to the online services
- Services mapped to the deployment with the online flag (Green or Orange)

OpenShift Components - Offline
- Routes and Services declared with suffix -offline
- Routes mapped only to the offline services
- Services mapped to the deployment with the offline flag (Green or Orange)

## Shop Umbrella Helm Chart

One of the best ways to package `Cloud Native` applications is Helm. But in blue/green deployment it have even more sense.
We have create a chart for each application that does not know anything about blue/green. Then we pack every thing together in a umbrella helm chart.

![Shop Umbrella Helm Chart](images/Shop-helm.png)

In the `Shop Umbrella Chart` we use several times the same charts as helm dependencies but with different names if they are blue/green or online/offline

This is the Chart.yaml
```
apiVersion: v2
name: shop-umbrella-blue-green
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "1.16.0"

dependencies:
  - name: quarkus-helm-discounts
    version: 0.1.0
    alias: discounts-blue
    tags:
      - discounts-blue
  - name: quarkus-helm-discounts
    version: 0.1.0
    alias: discounts-green
    tags:
      - discounts-green
  - name: quarkus-base-networking
    version: 0.1.0
    alias: discountsNetworkingOnline  
    tags:
      - discountsNetworkingOnline
  - name: quarkus-base-networking
    version: 0.1.0
    alias: discountsNetworkingOffline
    tags:
      - discountsNetworkingOffline
  - name: quarkus-helm-products
    version: 0.1.0
    alias: products-blue
    tags:
      - products-blue
  - name: quarkus-helm-products
    version: 0.1.0
    alias: products-green
    tags:
      - products-green
  - name: quarkus-base-networking
    version: 0.1.0
    alias: productsNetworkingOnline
    tags:
      - productsNetworkingOnline
  - name: quarkus-base-networking
    version: 0.1.0
    alias: productsNetworkingOffline
    tags:
      - productsNetworkingOffline
```

## OpenShift GitOps

If we want to have a `Cloud Native` deployment we can not forget `CI/CD`. `OpenShift GitOps` and `Openshift Pipelines` will help us. 
### Install OpenShift GitOps 

Log into OpenShift as a cluster admin and install the OpenShift GitOps operator with the following command:
```
oc apply -f gitops/gitops-operator.yaml
```

Once OpenShift GitOps is installed, an instance of Argo CD is automatically installed on the cluster in the `openshift-gitops` namespace and link to this instance is added to the application launcher in OpenShift Web Console.

![Application Launcher](images/gitops-link.png)

### Log into Argo CD dashboard

Argo CD upon installation generates an initial admin password which is stored in a Kubernetes secret. In order to retrieve this password, run the following command to decrypt the admin password:

```
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
```

Click on Argo CD from the OpenShift Web Console application launcher and then log into Argo CD with `admin` username and the password retrieved from the previous step.

![Argo CD](images/ArgoCD-login.png)

![Argo CD](images/ArgoCD-UI.png)

### Configure OpenShift with Argo CD

In the current Git repository, the [gitops/cluster-config](gitops/cluster-config/) directory contains OpenShift cluster configurations such as:
- namespaces `blue-green-gitops`.
- operator `Openshift Pipelines`.
- cluster role `tekton-admin-view`.
- role binding for ArgoCD to the namespace `blue-green-gitops`.
- `pipelines-blue-green` the pipelines that we will see later for blue/green deployment.
- `shop-blue-green` the application that we are going to use to test blue/green deployment


 Let's configure Argo CD to recursively sync the content of the [gitops/cluster-config](gitops/cluster-config/) directory to the OpenShift cluster.

Execute this command to add a new Argo CD application that syncs a Git repository containing cluster configurations with the OpenShift cluster.

```
oc apply -f gitops/application-cluster-config.yaml -n openshift-gitops
```

Looking at the Argo CD dashboard, you would notice that three applications has been created. 

![Argo CD - Applications](images/applications.png)

You can click on the **blue-green-cluster-configuration** application to check the details of sync resources and their status on the cluster. 

![Argo CD - Cluster Config](images/application-cluster-config-sync.png)


You can check that a namespace called `blue-green-gitops` is created on the cluster.

You can check that the **Openshift Pipelines operator** is installed.

And also the other to applications has been created **pipelines-blue-green** **shop-blue-green**



We have to get the Online and the Offline routes
```
oc get routes -n blue-green-gitops
```
TODO poner como probar que shop funciona

```
export TOKEN=XXXXXX
export GIT_USER=YYY
oc policy add-role-to-user edit system:serviceaccount:blue-green-gitops:pipeline --rolebinding-name=pipeline-edit -n blue-green-gitops
oc create secret generic github-token --from-literal=username=${GIT_USER} --from-literal=password=${TOKEN} --type "kubernetes.io/basic-auth" -n blue-green-gitops
oc annotate secret github-token "tekton.dev/git-0=https://github.com/davidseve" -n blue-green-gitops
oc secrets link pipeline github-token -n blue-green-gitops
tkn hub install task helm-upgrade-from-source -n blue-green-gitops
tkn hub install task kaniko -n blue-green-gitops
tkn hub install task git-cli -n blue-green-gitops
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/openshift-client/0.2/openshift-client.yaml -n blue-green-gitops
```

TODO lanzar los pipelines
TODO poner su usuario de github
oc create -f 1-pipelinerun-products-new-version.yaml -n blue-green-gitops
oc create -f 2-pipelinerun-products-configuration.yaml -n blue-green-gitops
oc create -f 3-pipelinerun-products-scale-up.yaml -n blue-green-gitops
oc create -f 4-pipelinerun-products-switch.yaml -n blue-green-gitops












TODO borrar
borrar todas las aplicaciones desde la web de Argo
borra los operadoes de pipelienes y gitops desde la web de openshift

