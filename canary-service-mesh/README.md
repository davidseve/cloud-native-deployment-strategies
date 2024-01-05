# Cloud Native Canary Deployment Strategy using Openshift Service Mesh

| :warning: WARNING          |
|:---------------------------|
| Work in progress           |
## Introduction

A critical topic in `Cloud Native` is the `Microservice Architecture`. We are not any more dealing with one monolithic application. We have several applications that have dependencies on each other and also have other dependencies like brokers or databases.
 
Applications have their own life cycle, so we should be able to execute independent canary deployment. All the applications and dependencies will not change their version at the same time.

Another important topic in the `Cloud Native` is `Continuous Delivery`. If we are going to have several applications doing canary deployment independently we have to automate it. We will use **Helm**, **Openshift Service Mesh**, **Openshift GitOps**, and of course **Red Hat Openshift** to help us.
**In the next steps we will see a real example of how to install, deploy and manage the life cycle of Cloud Native applications doing canary deployment using Openshift Service Mesh.**

Let's start with some theory...after it, we will have the **hands-on example**.

## Canary Deployment

A canary deployment is a strategy where the operator releases a new version of their application to a small percentage of the production traffic. This small percentage may test the new version and provide feedback. If the new version is working well the operator may increase the percentage, till all the traffic is using the new version. Unlike Blue/Green, canary deployments are smoother, and failures have limited impact. 

## Shop application
 
We are going to use very simple applications to test canary deployment. We have created two Quarkus applications `Products` and `Discounts`
 
![Shop Application](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/Shop.png)
 
`Products` call `Discounts` to get the product`s discount and expose an API with a list of products with its discounts.

## Shop Canary
 
To achieve canary deployment with `Cloud Native` applications using **Openshift Service Mesh**, we have designed this architecture. This is a simplification.

![Shop initial status](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/canary-mesh-initial.png)
 
OpenShift Components - Online

- Route, Gateway and Virtual Services.
- Services mapped to the deployment.

In Blue/Green deployment we always have an offline service to test the version that is not in production. In the case of canary deployment we do not need it because progressively we will have the new version in production. 


We have defined an active or online service 'products-umbrella-online'. The final user will always use 'products-umbrella-online'. When a new version is deployed **Openshift Service Mesh** will send the amount of traffic that has been defined in the Virtual Service. We have to take care of the number of replicas in the new release and the old release, based on the amount of traffic that we have defined in the Virtual Service.

## Shop Umbrella Helm Chart
 
One of the best ways to package `Cloud Native` applications is `Helm`. In canary deployment, it makes even more sense.
We have created a chart for each application that does not know anything about canary deployment. Then we pack everything together in an umbrella helm chart.

## Demo!!

### Prerequisites:

- **Red Hat Openshift 4.13** with admin rights.
  - You can download [Red Hat Openshift Local for OCP 4.13](https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/crc/2.6.0).
  - [Getting Started Guide](https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.5/html/getting_started_guide/using_gsg)
- [Git](https://git-scm.com/)
- [GitHub account](https://github.com/)
- [oc 4.13 CLI] (https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html)
 
We have a GitHub [repository](https://github.com/davidseve/cloud-native-deployment-strategies) for this demo. As part of the demo, you will have to make some changes and commits. So **it is important that you fork the repository and clone it in your local**.

```
git clone https://github.com/your_user/cloud-native-deployment-strategies
```
 
### Install OpenShift GitOps
 
Go to the folder where you have cloned your forked repository and create a new branch `canary-mesh`
```
git checkout -b canary-mesh 
git push origin canary-mesh 
```
 
Log into OpenShift as a cluster admin and install the OpenShift GitOps operator with the following command. This may take some minutes.
```
oc apply -f gitops/gitops-operator.yaml
```
 
Once OpenShift GitOps is installed, an instance of Argo CD is automatically installed on the cluster in the `openshift-gitops` namespace and a link to this instance is added to the application launcher in OpenShift Web Console.
 
![Application Launcher](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/gitops-link.png)
 
### Log into the Argo CD dashboard
 
Argo CD upon installation generates an initial admin password which is stored in a Kubernetes secret. To retrieve this password, run the following command to decrypt the admin password:
 
```
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
```
 
Click on Argo CD from the OpenShift Web Console application launcher and then log into Argo CD with `admin` username and the password retrieved from the previous step.
 
![Argo CD](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/ArgoCD-login.png)
 
![Argo CD](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/ArgoCD-UI.png)
 
### Configure OpenShift with Argo CD
 
We are going to follow, as much as we can, a GitOps methodology in this demo. So we will have everything in our Git repository and use **ArgoCD** to deploy it in the cluster.
 
In the current Git repository, the [gitops/cluster-config](https://github.com/davidseve/cloud-native-deployment-strategies/tree/main/gitops/cluster-config) directory contains OpenShift cluster configurations such as:

- namespaces `gitops`.
- role binding for ArgoCD to the namespace `gitops`.
- **OpenShift Service Mesh**
- **Kiali Operator**
- **OpenShift Elasticsearch Operator**
- **Red Hat OpenShift distributed tracing platform**
 
Let's configure Argo CD to recursively sync the content of the [gitops/cluster-config](https://github.com/davidseve/cloud-native-deployment-strategies/tree/main/gitops/cluster-config) directory into the OpenShift cluster.
 
Execute this command to add a new Argo CD application that syncs a Git repository containing cluster configurations with the OpenShift cluster.
 
```
oc apply -f canary-service-mesh/application-cluster-config.yaml
```
 
Looking at the Argo CD dashboard, you will notice that an application has been created.

You can click on the `cluster-configuration` application to check the details of sync resources and their status on the cluster.

### Create Shop application

We are going to create the application `shop`, that we will use to test canary deployment. Because we will make changes in the application's GitHub repository, we have to use the repository that you have just forked. Please edit the file `canary-service-mesh/application-shop-mesh.yaml` and set your own GitHub repository in the `reportURL` and the OCP cluster domain in `change_domain`.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: shop
  namespace: openshift-gitops
spec:
  destination:
    name: ''
    namespace: gitops
    server: 'https://kubernetes.default.svc'
  source:
    path: helm/quarkus-helm-umbrella/chart
    repoURL:  https://github.com/change_me/cloud-native-deployment-strategies.git
    targetRevision: canary-mesh
    helm:
      valueFiles:
        - values/values-mesh.yaml
      parameters:
      - name: "global.namespace"
        value: gitops
      - name: "domain"
        value: "change_domain"
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

```

```
oc apply -f canary-service-mesh/application-shop-mesh.yaml
```

Looking at the Argo CD dashboard, you will notice that we have a new `shop` application.


## Test Shop application
 
We have deployed the `shop` with ArgoCD. We can test that it is up and running.
 
We have to get the route that we have created.
```
oc get routes shop-umbrella-products-route -n istio-system --template='http://{{.spec.host}}/products'
```

Notice that in each microservice response, we have added metadata information to see better the `version` of each application. This will help us to see the changes while we do the canary deployment.
We can see that the current version is `v1.0.1`:
```json
{
   "products":[
      {
         ...
         "name":"TV 4K",
         "price":"1500€"
      }
   ],
   "metadata":{
      "version":"v1.0.1", <--
      "colour":"none",
      "mode":"online"
   }
}
```
## Products Canary deployment
 
We have already deployed the products version v1.0.1 with 2 replicas, and we are ready to use a new products version v1.1.1 that has a new `description` attribute.

This is our current status:
![Shop initial status](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/canary-mesh-step-0.png) -->

We have split a `Cloud Native` Canary deployment into three automatic step:

1. Deploy canary version for 10%
2. Scale canary version to 50%
3. Scale canary version to 100%

This is just an example. The key point here is that, very easily we can have the canary deployment that better fits our needs. 

### Step 1 - Deploy canary version for 10%
 
We will deploy a new version v1.1.1. To do it, we have already configure products-green with the new version v1.1.1. And we have to edit the file `helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml` and do some changes:

1. In `global.istio` change the weight to send 10% of the traffic to the new version.

```yaml
global:
  istio:
    productsblueWeight: 90
    productsgreenWeight: 10
```

2. Increase the number of replicas to be able to support the 10% of the traffic in the new version.

```yaml
products-green:
  quarkus-base:
    replicaCount: 1
```

Push the changes to start the deployment.
```
git add .
git commit -m "Deploy products v1.1.1 with 10% traffic"
git push origin canary-mesh 
```

ArgoCD will refresh the status after some minutes. If you don't want to wait you can refresh it manually from ArgoCD UI or configure the Argo CD Git Webhook.[^note2].
 
[^note2]:
    Here you can see how to configure the Argo CD Git [Webhook]( https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/)
    ![Argo CD Git Webhook](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/ArgoCD-webhook.png)

This is our current status:
![Shop Step 1](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/canary-mesh-step-1.png)


In the products url`s response you will have the new version in 10% of the requests.

New revision:
```json
{
  "products":[
     {
        "discountInfo":{...},
        "name":"TV 4K",
        "price":"1500€",
        "description":"The best TV" <--
     }
  ],
  "metadata":{
     "version":"v1.1.1", <--
  }
}
```

Old revision:
```json
{
  "products":[
     {
        "discountInfo":{...},
        "name":"TV 4K",
        "price":"1500€"
     }
  ],
  "metadata":{
     "version":"v1.0.1", <--
  }
}
```
### Step 2 - Scale canary version to 50%

Now we have to make the changes to send 50% of the traffic to the new version v1.1.1. We have to edit the file `helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml`.

1. In `global.istio` change the weight to send 50% of the traffic to the new version.

```yaml
global:
  istio:
    productsblueWeight: 50
    productsgreenWeight: 50
```

2. Increase the number of replicas to be able to support 50% of the traffic in the new version.

```yaml
products-green:
  quarkus-base:
    replicaCount: 2
```

Push the changes to start the deployment.
```
git add .
git commit -m "Deploy products v1.1.1 with 50% traffic"
git push origin canary-mesh 
```

This is our current status:
![Shop Step 2](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/canary-mesh-step-2.png)

In the products url`s response, you will have the new version in 50% of the requests.


### Step 3 - Scale canary version to 100%

Now we have to do the changes to send 100% of the traffic to the new version v1.1.1. We have to edit the file `helm/quarkus-helm-umbrella/chart/values/values-mesh.yaml`.

1. In `global.istio` change the weight to send 50% of the traffic to the new version.

```yaml
global:
  istio:
    productsblueWeight: 0
    productsgreenWeight: 100
```

2. We can decrease the number of replicas in the old version, becuase it will not recived traffic.

```yaml
products-blue:
  quarkus-base:
    replicaCount: 0
```

Push the changes to start the deployment.
```
git add .
git commit -m "Delete product v1.0.1"
git push origin canary-mesh 
```
This is our current status:
![Shop Step 3](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/canary-mesh-step-3.png)

In the products url`s response, you will only have the new version v1.1.1!!!
```json
{
  "products":[
     {
        "discountInfo":{...},
        "name":"TV 4K",
        "price":"1500€",
        "description":"The best TV" <--
     }
  ],
  "metadata":{
     "version":"v1.1.1", <--
  }
}
```

## Delete environment
 
To delete all the things that we have done for the demo you have to:

- In GitHub delete the branch `canary-mesh`
- In ArgoCD delete the application `cluster-configuration` and `shop`
- In Openshift, go to project `openshift-operators` and delete the installed operators **Openshift GitOps**, **OpenShift Service Mesh**, **Kiali Operator**, **OpenShift Elasticsearch Operator**, **Red Hat OpenShift distributed tracing platform**


