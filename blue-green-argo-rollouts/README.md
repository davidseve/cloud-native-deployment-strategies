# Cloud Native Argo Rollouts Blue/Green Deployment

## Shop application
 
We are going to use very simple applications to test Blue/Green deployment. We have create two Quarkus applications `Products` and `Discounts`
 
![Shop Application](../images/Shop.png)
 
`Products` call `Discounts` to get the product`s discount and expose an API with a list of products with its discounts.
 
## Shop Blue/Green
 
To achieve blue/green deployment with `Cloud Native` applications we have designed this architecture.
 
OpenShift Components - Online
- Routes and Services declared with suffix -online
- Routes mapped only to the online services
- Services mapped to the deployment.
 
OpenShift Components - Offline
- Routes and Services declared with suffix -offline
- Routes mapped only to the offline services
- Services mapped to the deployment

 
## Shop Umbrella Helm Chart
 
One of the best ways to package `Cloud Native` applications is `Helm`. In blue/green deployment it makes even more sense.
We have created a chart for each application that does not know anything about blue/green. Then we pack everything together in an umbrella helm chart.

## Demo!!

First step is to fork this repository, you will have to do some changes and commits. You should clone your forked repository in your local.
 
### Install OpenShift GitOps
 
Go to the folder where you have clone your forked repository and create a new branch `rollouts`
```
git checkout -b rollouts
git push origin rollouts
```
 
Log into OpenShift as a cluster admin and install the OpenShift GitOps operator with the following command. This may take some minutes.
```
oc apply -f gitops/gitops-operator.yaml
```
 
Once OpenShift GitOps is installed, an instance of Argo CD is automatically installed on the cluster in the `openshift-gitops` namespace and a link to this instance is added to the application launcher in OpenShift Web Console.
 
![Application Launcher](../images/gitops-link.png)
 
### Log into Argo CD dashboard
 
Argo CD upon installation generates an initial admin password which is stored in a Kubernetes secret. In order to retrieve this password, run the following command to decrypt the admin password:
 
```
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
```
 
Click on Argo CD from the OpenShift Web Console application launcher and then log into Argo CD with `admin` username and the password retrieved from the previous step.
 
![Argo CD](../images/ArgoCD-login.png)
 
 
### Configure OpenShift with Argo CD
 
We are going to follow, as much as we can, a GitOps methodology in this demo. So we will have everything in our Git repository and use **ArgoCD** to deploy it in the cluster.
 
In the current Git repository, the [gitops/cluster-config](../gitops/cluster-config/) directory contains OpenShift cluster configurations such as:
- namespaces `gitops`.
- role binding for ArgoCD to the namespace `gitops`.
- Argo Rollouts project.
 
Let's configure Argo CD to recursively sync the content of the [gitops/cluster-config](../gitops/cluster-config/) directory to the OpenShift cluster.
 
Execute this command to add a new Argo CD application that syncs a Git repository containing cluster configurations with the OpenShift cluster.
 
```
oc apply -f blue-green-argo-rollouts/application-cluster-config.yaml
```
 
Looking at the Argo CD dashboard, you would notice that an application has been created.

You can click on the `cluster-configuration` application to check the details of sync resources and their status on the cluster.

### Create Shop application

We are going to create the application `shop`, that we are going to use to test blue/green deployment.

```
oc apply -f blue-green-argo-rollouts/application-shop-blue-green-rollouts.yaml
```

Looking at the Argo CD dashboard, you would notice that we have a new `shop` application.


## Test Shop application
 
We have deployed the `shop` with ArgoCD. We can test that it is up and running.
 
We have to get the Online route
```
echo "$(oc get routes products-umbrella-online -n gitops --template='http://{{.spec.host}}')/products"
```
And the Offline route
```
echo "$(oc get routes products-umbrella-offline -n gitops --template='http://{{.spec.host}}')/products"
```
We can also see the rollout`s status[^note].

[^note]:
    Argo Rollouts offers a Kubectl plugin to enrich the experience with Rollouts https://argoproj.github.io/argo-rollouts/installation/#kubectl-plugin-installation 

```
kubectl argo rollouts get rollout products --watch -n gitops
```

 
## Products Blue/Green deployment
 
We have split a `Cloud Native` Blue/Green deployment in two steps:
1. Deploy new version.
2. Promote new version
 

 
We have already deployed the product's version v1.0.1, and we have ready to use a new product's version v1.1.1 that has a new `description` attribute.
 
### Step 1 - Deploy new version
 
We will deploy a new version v1.1.1
In the file `helm/quarkus-helm-umbrella/chart/values/values-rollouts.yaml` under `products-blue` set `tag` value to `v.1.1.1`

```yaml
products-blue:
  mode: online
  image:
    tag: v1.1.1
```

And push the changes
```
git add .
git commit -m "Change products version to v1.1.1"
git push origin rollouts
```

 ArgoCD will refresh the status after some minutes. If you don't want to wait you can refresh it manually from ArgoCD UI.
![Refresh Shop](../images/ArgoCD-Shop-Refresh.png)
 
**Argo Rollouts** will automatically deploy the new products version and execute the promotion analysis. 
 
 
If the promotion analysis goes well, we can see that offline applications have the version v1.1.1 and the new attribute description, but the online has not changed.
 
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
Functional testing users can execute `Smoke tests` to validate this new v1.1.1 version.

We have to be careful with those tests in a production environment because the product microservice will call the online dependencies.
If this dependency is for example a production DB we will create the things that our `Smoke tests` do.
 
### Step 2 - Promote new version
 
We are going to open the new version to final users. **Argo Rollouts** will just change the service to use the new release (ReplicaSet).  We also `minimize downtime` because it just changes the service label. And after `scaleDownDelaySeconds` **Argo Rollouts** will delete the first release (v1.0.1).

```
kubectl argo rollouts promote products
```

 


**We have in the online environment the new version v1.1.1!!!**
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
 
To delete all the thing that we have done for the demo you have to_
- In GitHub delete the branch `rollouts`
- In ArgoCD delete the application `cluster-configuration` and `shop`
- In Openshift, go to project `openshift-operators` and delete the installed operators **Openshift GitOps**


