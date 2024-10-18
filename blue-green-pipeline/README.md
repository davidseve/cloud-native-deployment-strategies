# Cloud Native Blue/Green Deployment Strategy using Openshift Pipelines
 
## Introduction
 
A critical topic in `Cloud Native` applications is the deployment strategy. We are no longer dealing with one monolithic application. We have several applications that have dependencies on each other and also have other dependencies like brokers or databases.
 
Applications have their own life cycle, so we should be able to execute independent Blue/Green deployment. All the applications and dependencies will not change their version at the same time.
 
Another important topic in `Cloud Native` is `Continuous Delivery`. If we are going to have several applications doing Blue/Green deployment independently we have to automate it. We will use **Helm**, **Openshift Pipelines**, **Openshift GitOps**, and of course **Red Hat Openshift** to help us.
 
**In the next steps, we will see a real example of how to install, deploy and manage the life cycle of Cloud Native applications doing Blue/Green deployment.**
 
Let's start with some theory...after that, we will have a **hands-on example**.
 
## Blue/Green Deployment
 
Blue green deployment is an application release model that transfers user traffic from a previous version of an app or microservice to a nearly identical new release, both of which are running in production.

For instance, the old version can be called the blue environment while the new version can be known as the green environment. Once production traffic is transferred from blue to green, blue can stand by in case of rollback or pulled from production and updated to become the template upon which the next update is made.
 
Advantages:

- Minimize downtime
- Rapid way to rollback
- Smoke testing
 
Disadvantages:

- Doubling of total resources
- Backward compatibility
 
 
![Blue/Green](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/blue-green.png)
 
We have two versions up and running in production, online and offline. The routers and services never change, they are always online or offline.
Because we have an offline version, we can do the **smoke test** before switching to online.
When a new version is ready to be used by the final users, we only change the deployment that the online service is using.
 
![Blue/Green Switch](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/blue-green-switch.png)
 
There is **minimal downtime** and we can do a **rapid rollback** just by undoing the changes in the services.
 
Meanwhile, we are validating the new version with real users, we have to be ready to do a rapid rollback. We need the **doubling or total resources** (we will see how to minimize this).
It is also very important to keep **backward compatibility**. Without it, we can not do independent Blue/Green deployments.
## Shop application
 
We are going to use very simple applications to test Blue/Green deployment. We have created two Quarkus applications `Products` and `Discounts`
 
![Shop Application](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/Shop.png)
 
`Products` call `Discounts` to get the product`s discount and expose an API with a list of products with its discounts.
 
## Shop Blue/Green
 
To achieve Blue/Green deployment with `Cloud Native` applications we have designed this architecture.
 
![Shop Blue/Green](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/Shop-blue-green.png)
 
OpenShift Components - Online

- Routes and Services declared with the suffix -online
- Routes mapped only to the online services
- Services mapped to the deployment with the color flag (Green or Orange)
 
OpenShift Components - Offline

- Routes and Services declared with the suffix -offline
- Routes mapped only to the offline services
- Services mapped to the deployment with the color flag (Green or Orange)
 
**Notice that the routers and services do not have color, this is because they never change, and they are always online or offline. However, deployments and pods will change their version.**
 
## Shop Umbrella Helm Chart
 
One of the best ways to package `Cloud Native` applications is `Helm`. In Blue/Green deployment it makes even more sense.
We have created a chart for each application that does not know anything about Blue/Green. Then we pack everything together in an umbrella helm chart.
 
![Shop Umbrella Helm Chart](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/Shop-helm.png)
 
## Demo!!

### Prerequisites:

- **Red Hat Openshift 4.16** with admin rights.
  - You can download [Red Hat Openshift Local for OCP 4.16](https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/crc/2.6.0).
  - [Getting Started Guide](https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.5/html/getting_started_guide/using_gsg)
- [Git](https://git-scm.com/)
- [GitHub account](https://github.com/)
- [oc 4.16 CLI](https://docs.openshift.com/container-platform/4.16/cli_reference/openshift_cli/getting-started-cli.html)
 
We have a GitHub [repository](https://github.com/davidseve/cloud-native-deployment-strategies) for this demo. As part of the demo, you will have to do some changes and commits. So **it is important that you fork the repository and clone it in your local**.

```
git clone https://github.com/your_user/cloud-native-deployment-strategies
```
 
If we want to have a `Cloud Native` deployment we can not forget `CI/CD`. **Red Hat OpenShift GitOps** and **Red Hat Openshift Pipelines** will help us.
### Install OpenShift GitOps
 
Go to the folder where you have cloned your forked repository and create a new branch `blue-green`
```
cd cloud-native-deployment-strategies
git checkout -b blue-green
git push origin blue-green
```
 
Log into OpenShift as a cluster admin and install the OpenShift GitOps operator with the following command. This may take some minutes.
```
oc apply -f gitops/gitops-operator.yaml
```
 
Once OpenShift GitOps is installed, an instance of Argo CD is automatically installed on the cluster in the `openshift-gitops` namespace and a link to this instance is added to the application launcher in OpenShift Web Console.
 
![Application Launcher](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/gitops-link.png)
 
### Log into Argo CD dashboard
 
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
- operator **Openshift Pipelines**.
- cluster role `tekton-admin-view`.
- role binding for ArgoCD and Pipelines to the namespace `gitops`.
- `pipelines-blue-green` the pipelines that we will see later for Blue/Green deployment.
- Tekton cluster role.
- Tekton tasks for git and Openshift clients.
 
Let's configure Argo CD to recursively sync the content of the [gitops/cluster-config](https://github.com/davidseve/cloud-native-deployment-strategies/tree/main/gitops/cluster-config) directory into the OpenShift cluster.

But first, we have to set your GitHub credentials. Please edit the file `blue-green-pipeline/application-cluster-config.yaml`.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-configuration
  namespace: openshift-gitops
spec:
  destination:
    name: ''
    namespace: openshift-gitops
    server: 'https://kubernetes.default.svc'
  source:
    path: gitops/cluster-config
    repoURL: 'https://github.com/davidseve/cloud-native-deployment-strategies.git'
    targetRevision: HEAD
    helm:
     parameters:
      - name: "bluegreen.enabled"
        value: "true"
      - name: "github.token"
        value: "changeme_token"
      - name: "github.user"
        value: "changeme_user"
      - name: "github.mail"
        value: "changeme_mail"
      - name: "github.repository"
        value: "changeme_repository"
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
 
Execute this command to add a new Argo CD application that syncs a Git repository containing cluster configurations with the OpenShift cluster.
 
```
oc apply -f blue-green-pipeline/application-cluster-config.yaml
```
 
Looking at the Argo CD dashboard, you would notice that an application has been created.

You can click on the `cluster-configuration` application to check the details of sync resources and their status on the cluster.
 
![Argo CD - Cluster Config](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/application-cluster-config-sync.png)

### Create Shop application

We are going to create the application `shop`, that we will use to test Blue/Green deployment. Because we will make changes in the application's GitHub repository, we have to use the repository that you have just forked. Please edit the file `blue-green-pipeline/application-shop-blue-green.yaml` and set your own GitHub repository in the `reportURL`.

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
    targetRevision: blue-green
    helm:
      valueFiles:
        - values/values.yaml
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

```
oc apply -f blue-green-pipeline/application-shop-blue-green.yaml
```

Looking at the Argo CD dashboard, you would notice that we have a new `shop` application.

![Argo CD - Cluster Config](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/ArgoCD-Applications.png)


## Test Shop application
 
We have deployed the `shop` with ArgoCD. We can test that it is up and running.
 
We have to get the Online route
```
curl -k "$(oc get routes products-umbrella-online -n gitops --template='https://{{.spec.host}}')/products"
```
And the Offline route
```
curl -k "$(oc get routes products-umbrella-offline -n gitops --template='https://{{.spec.host}}')/products"
```
Notice that in each microservice response, we have added metadata information to see better the `version`, `color`, and `mode` of each application. This will help us to see the changes while we do the Blue/Green deployment.
Because right now we have the same version v1.0.1 in both colors we will have almost the same response, only the mode will change.
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
              "mode":"online" <--
           }
        },
        "name":"TV 4K",
        "price":"1500€"
     }
  ],
  "metadata":{
     "version":"v1.0.1",
     "colour":"blue",
     "mode":"online" <--
  }
}
```
 
## Products Blue/Green deployment
 
We have split a `Cloud Native` Blue/Green deployment into three steps:

1. Deploy the new version.
2. Switch the new version to Online.
   - Rollback
3. Align and scale down Offline.
 

 
We have already deployed the products version v1.0.1, and we are ready to use a new products version v1.1.1 that has a new `description` attribute.
 
This is our current status:
![Shop initial status](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/blue-green-step-0.png)
 
 
### Step 1 - Deploy the new version
 
We will start deploying a new version v1.1.1 in the offline color. But instead of going manually to see which is the offline color and deploying the new version on it, let's let the pipeline find the current offline color and automatically deploy the new version, with no manual intervention.
We will use the already created pipelinerun.

Those are the main tasks that are executed:

- Set new tag image values in the right color and commit the changes.
- Execute E2E test to validate the new version.
- Change the application configuration values to use the online services and commit the changes.
- Scale Up the offline color and commit the changes.

```
cd blue-green-pipeline/pipelines/run-products
oc create -f 1-pipelinerun-products-new-version.yaml -n gitops
```
![Pipeline step 1](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/pipeline-step-1.png)

This pipeline may take more time because we are doing three different commits, so ArgoCD has to synchronize them to continue with the pipeline. If you want to make it faster, you can refresh ArgoCD manually after each `commit-*` step or configure the Argo CD Git Webhook.[^note2].
 
[^note2]:
    Here you can see how to configure the Argo CD Git [Webhook]( https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/)
    ![Argo CD Git Webhook](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/ArgoCD-webhook.png)




![Refresh Shop](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/ArgoCD-Shop-Refresh.png)
 
After the pipeline is finished and ArgoCD has synchronized the changes this will be the `Shop` status:
![Shop step 1](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/blue-green-step-1.png)
 
 
See that offline applications have version v1.1.1 and the new attribute description, but the online has not changed.
 
```json
{
  "products":[
     {
        "discountInfo":{
            "discounts":[...],
            "metadata":{
               "version":"v1.0.1",
               "colour":"blue",
               "mode":"online" <--
            }
        }, 
        "name":"TV 4K",
        "price":"1500€",
        "description":"The best TV" <--
     }
  ],
  "metadata":{
     "version":"v1.1.1", <--
     "colour":"green",
     "mode":"online" <--
  }
}
```
Functional testing users can execute `Smoke tests` to validate this new v1.1.1 version.
 
### Step 2 - Switch new version to Online
 
We are going to open the new version to final users. The pipeline will just change the service to use the other color. Again the pipeline does this automatically without manual intervention. We `minimize downtime` because it just changes the service label.
```
oc create -f 2-pipelinerun-products-switch.yaml -n gitops
```

![Pipeline step 2](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/pipeline-step-3.png)
After the pipeline is finished and ArgoCD has synchronized the changes this will be the `Shop` status:
![Shop step 2](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/blue-green-step-2.png)
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
     "colour":"green",
     "mode":"online" <--
  }
}
```
 
### Step 2,5 - Rollback
 
Imagine that something goes wrong, we know that this never happens but just in case. We can do a very `quick rollback` just by undoing the change in the `Products` online service. But, are we sure that with all the pressure that we will have at this moment, we will find the right service and change the label to the right color? Let's move this pressure to the pipeline. We can have a pipeline for rollback.
```
oc create -f 2-pipelinerun-products-switch-rollback.yaml -n gitops
```

![Pipeline step 2,5 Rollback](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/pipeline-step-3-rollback.png)
After the pipeline is finished and ArgoCD has synchronized the changes this will be the `Shop` status:
![Shop step 2,5 Rollback](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/blue-green-step-2-5.png)
We have version v1.0.1 online again.
```json
{
  "products":[
     {
        "discountInfo":{...},
        "name":"TV 4K",
        "price":"1500€",
     }
  ],
  "metadata":{
     "version":"v1.0.1", <--
     "colour":"blue",
     "mode":"online" <--
  }
}
```
 
After fixing the issue we can execute the Switch step again.
```
oc create -f 2-pipelinerun-products-switch.yaml -n gitops
```
![Shop step 2](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/blue-green-step-2.png)
We have in the online environment the new version v1.1.1 again.
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
     "colour":"green",
     "mode":"online" <--
  }
}
```
### Step 3 - Align and scale down Offline
 
Finally, when online is stable we should align offline with the new version and scale it down. Does not make sense to use the same resources that we have in online.
```
oc create -f 3-pipelinerun-products-scale-down.yaml -n gitops
```

![Pipeline step 3](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/pipeline-step-4.png)
After the pipeline is finished and ArgoCD has synchronized the changes this will be the `Shop` status:
![Shop step 3](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/blue-green-step-3.png)
We can see that the offline `Products` is calling offline `Discounts` and has the new version v1.1.1
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
## Delete environment
 
To delete all the things that we have done for the demo you have to:

- In GitHub delete the branch `blue-green`
- In ArgoCD delete the application `cluster-configuration` and `shop`
- In Openshift, go to project `openshift-operators` and delete the installed operators **Openshift GitOps** and **Openshift Pipelines**


