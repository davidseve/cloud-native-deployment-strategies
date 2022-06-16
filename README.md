# Cloud Native Blue/Green

## Introduction

One important topic in the `Cloud Native` is the `Microservice Architecture`. We are not any more dealing wih one monolithic application. We have several applications that have dependencies on each other and also has other dependencies like brokers or data bases. 

Applications have its own life cycle, so we should be able to execute independent blue/green deployment. All the applications and dependencies will not change its version at the same time. 

Another important topic in the `Cloud Native` is the `Continuos Delivery`. If we are going to have several applications doing Blue/Green deployment independently we have to automate it. We will use **Helm**, **Openshift Pipelines**, **Openshift GitOps** and of course **Red Hat Openshift** to help us.

**In the next steps we will see a real example of how to install, deploy and manage the life cycle of Cloud Native applications doing Blue/Green deployment.** 

Let`s start with some theory...after it we will have the **hands on example**.

## Blue/Green Deployment

Blue green deployment is an application release model that transfers user traffic from a previous version of an app or microservice to a nearly identical new release, both of which are running in production.
The old version can be called the blue environment while the new version can be known as the green environment. Once production traffic is transferred from blue to green, blue can standby in case of rollback or pulled from production and updated to become the template upon which the next update is made.

Advantages:
- Minimize downtime
- Rapid way to rollback 
- Smoke testing

Disadvantages:
- Doubling of total resources
- Backwards compatibility


![Blue/Green](images/blue-green.png)

We have two versions up and running in production, online and offline. The routers and services never change, they are always online or offline. 
Because we have an offline version, we can do **smoke test** before switch it to online.
When a new version is ready to be use by the users we only change the deployment that the online service is using.

![Blue/Green Switch](images/blue-green-switch.png)

There is **minimum downtime** and we can do a **rapid rollback** just undoing the changes in the services.

However, main while we are going to do the switch, and we want to be really to do a rapid rollback. We need the **doubling or total resources**, we will see how to minimize this.
It is also very important to keep **backwards compatibility**. With out it, we can not do independent Blue/Green deployments.
## Shop application

We are going to use very simple applications to test Blue/Green deployment. We have create two Quarkus applications `Products` and `Discounts`

![Shop Application](images/Shop.png)

`Products` call `Discounts` to get the product`s discount and expose an API with a list of products with its discounts.

## Shop Blue/Green

To achieve blue/green deployment with `Cloud Native` applications we have design this architecture.

![Shop Blue/Green](images/Shop-blue-green.png)

OpenShift Components - Online
- Routes and Services declared with suffix -online
- Routes mapped only to the online services
- Services mapped to the deployment with the color flag (Green or Orange)

OpenShift Components - Offline
- Routes and Services declared with suffix -offline
- Routes mapped only to the offline services
- Services mapped to the deployment with the color flag (Green or Orange)

Notice that the routers and services does not have color, this is because they never change, they are always online or offline. However deployments and pods will change their version.

## Shop Umbrella Helm Chart

One of the best ways to package `Cloud Native` applications is `Helm`. In blue/green deployment it have even more sense.
We have create a chart for each application that does not know anything about blue/green. Then we pack every thing together in a umbrella helm chart.

![Shop Umbrella Helm Chart](images/Shop-helm.png)

In the `Shop Umbrella Chart` we use several times the same charts as helm dependencies but with different names if they are blue/green or online/offline. This will allow as to have different configuration for each color.

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

We have package both applications in one chart, but we may have different umbrella chart per application.

## Demo!!

First step is to fork this repository, you will have to do some changes and commits. You should clone your forked repository in your local. 


If we want to have a `Cloud Native` deployment we can not forget `CI/CD`. `OpenShift GitOps` and `Openshift Pipelines` will help us.
### Install OpenShift GitOps 

Go to he folder where you have clone your forked repository and creare a new branch `blue-green`
```
git checkout -b blue-green
```

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

We are going to follow, as much as we can, a GitOps methodology in this demo. So we will have every thing in our Git repository and use **ArgoCD** to deploy it in the cluster.

In the current Git repository, the [gitops/cluster-config](gitops/cluster-config/) directory contains OpenShift cluster configurations such as:
- namespaces `blue-green-gitops`.
- operator **Openshift Pipelines**.
- cluster role `tekton-admin-view`.
- role binding for ArgoCD to the namespace `blue-green-gitops`.
- `pipelines-blue-green` the pipelines that we will see later for blue/green deployment.
- `shop-blue-green` the application that we are going to use to test blue/green deployment


 Let's configure Argo CD to recursively sync the content of the [gitops/cluster-config](gitops/cluster-config/) directory to the OpenShift cluster.

Execute this command to add a new Argo CD application that syncs a Git repository containing cluster configurations with the OpenShift cluster.

```
oc apply -f gitops/application-cluster-config.yaml -n openshift-gitops
```

Looking at the Argo CD dashboard, you would notice that three applications has been created[^note]. 

[^note]:
     `pipelines-blue-green` will have status `Progressing` till we execute the first pipeline.

![Argo CD - Applications](images/applications.png)

You can click on the `blue-green-cluster-configuration` application to check the details of sync resources and their status on the cluster. 

![Argo CD - Cluster Config](images/application-cluster-config-sync.png)


You can check that a namespace called `blue-green-gitops` is created on the cluster, the **Openshift Pipelines operator** is installed, and also the other to applications has been created `pipelines-blue-green` and `shop-blue-green`

## Test Shop application

We have deploy the `shop-blue-green` with ArgoCD. We can test that is up and running.

We have to get the Online route
```
echo "$(oc get routes products-umbrella-online -n blue-green-gitops --template='http://{{.spec.host}}')/products"
```
And the offline route
```
echo "$(oc get routes products-umbrella-offline -n blue-green-gitops --template='http://{{.spec.host}}')/products"
```

Becaus right now we have the same version v1.0.0 in both colors we will have the same response
```json
{
   "products":[
      {
         "discountInfo":{
            "discounts":[
               {
                  "name":"BlackFriday",
                  "price":"1350€",
                  "discount":"10%"
               }
            ],
            "metadata":{
               "version":"v1.0.1",
               "colour":"blue",
               "mode":"online"
            }
         },
         "name":"TV 4K",
         "price":"1500€"
      }
   ],
   "metadata":{
      "version":"v1.0.1",
      "colour":"blue",
      "mode":"online"
   }
}
```
Notices that in the each microservice response we have add metadata information to see better the `version`, `color`, `mode` of each applications. This will help us to see the changes while we do the Blue/Green deployment.
```json
   "metadata":{
      "version":"v1.0.1",
      "colour":"blue",
      "mode":"online"
   }
```



TODO ver donde meter esto
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

## Products Blue/Green deployment
TODO
We have created a pipeline with differents step to 
We have already create a new product's version v1.1.1




TODO lanzar los pipelines
TODO poner su usuario de github
oc create -f 1-pipelinerun-products-new-version.yaml -n blue-green-gitops

See that offline applications has the version v1.1.1 and the new atribute description.

```json
{
   "products":[
      {
         "discountInfo":{...},
         "name":"TV 4K",
         "price":"1500€",
         "description":"The best TV"
      }
   ],
   "metadata":{
      "version":"v1.1.1",
      "colour":"green",
      "mode":"offline"
   }
}
```

oc create -f 2-pipelinerun-products-configuration.yaml -n blue-green-gitops
First will change ths configuratoin and scale to 0
Second will scale up the application to production number of replicas
We can see that now Products is calling Discouts online application

In this point the applicatin is ready to recived real trafic from the users. We can see that now Products is calling Discouts online application
```json
"discountInfo":{
   "discounts":[...],
   "metadata":{
      "version":"v1.0.1",
      "colour":"blue",
      "mode":"online"
   }
}
```

oc create -f 3-pipelinerun-products-switch.yaml -n blue-green-gitops
We have in the online enviroment the new version v1.1.1
```json
{
   "products":[
      {
         "discountInfo":{...},
         "name":"TV 4K",
         "price":"1500€",
         "description":"The best TV"
      }
   ],
   "metadata":{
      "version":"v1.1.1",
      "colour":"green",
      "mode":"online"
   }
}
```
oc create -f 4-pipelinerun-products-scale-down.yaml -n blue-green-gitops

Finnaly we aligne the offline colour with the new version v1.1.1 and with the offline configuration (calling the offline Discounts application)

```json
{
   "products":[
      {
         "discountInfo":{
            "discounts":[
               {
                  "name":"BlackFriday",
                  "price":"1350€",
                  "discount":"10%",
                  "description":null
               }
            ],
            "metadata":{
               "version":"v1.0.1",
               "colour":"green",
               "mode":"offline" <--
            }
         },
         "name":"TV 4K",
         "price":"1500€",
         "description":"The best TV"
      }
   ],
   "metadata":{
      "version":"v1.1.1", <--
      "colour":"blue",
      "mode":"offline" <--
   }
}
```












TODO borrar
borrar todas las aplicaciones desde la web de Argo
borra los operadoes de pipelienes y gitops desde la web de openshift

