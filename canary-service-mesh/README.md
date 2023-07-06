# Cloud Native Canary Deployment Strategy using Openshift Service Mesh

| :warning: WARNING          |
|:---------------------------|
| Work in progress           |

## Shop application
 
We are going to use very simple applications to test canary deployment. We have create two Quarkus applications `Products` and `Discounts`
 
![Shop Application](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/Shop.png)
 
`Products` call `Discounts` to get the product`s discount and expose an API with a list of products with its discounts.
 
## Shop Umbrella Helm Chart
 
One of the best ways to package `Cloud Native` applications is `Helm`. In canary deployment it makes even more sense.
We have created a chart for each application that does not know anything about canary deployment. Then we pack everything together in an umbrella helm chart.

## Demo!!

### Prerequisites:

- **Red Hat Openshift 4.12** with admin rights.
  - You can download [Red Hat Openshift Local for OCP 4.12](https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/crc/2.6.0).
  - [Getting Started Guide](https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.5/html/getting_started_guide/using_gsg)
- [Git](https://git-scm.com/)
- [GitHub account](https://github.com/)
- [oc 4.12 CLI] (https://docs.openshift.com/container-platform/4.12/cli_reference/openshift_cli/getting-started-cli.html)
 
We have a GitHub [repository](https://github.com/davidseve/cloud-native-deployment-strategies) for this demo. As part of the demo, you will have to do some changes and commits. So **it is important that you fork the repository and clone it in your local**.

```
git clone https://github.com/your_user/cloud-native-deployment-strategies
```
 
### Install OpenShift GitOps
 
Go to the folder where you have clone your forked repository and create a new branch `mesh`
```
git checkout -b mesh
git push origin mesh
```
 
Log into OpenShift as a cluster admin and install the OpenShift GitOps operator with the following command. This may take some minutes.
```
oc apply -f gitops/gitops-operator.yaml
```
 
Once OpenShift GitOps is installed, an instance of Argo CD is automatically installed on the cluster in the `openshift-gitops` namespace and a link to this instance is added to the application launcher in OpenShift Web Console.
 
![Application Launcher](https://github.com/davidseve/cloud-native-deployment-strategies/raw/main/images/gitops-link.png)
 
### Log into Argo CD dashboard
 
Argo CD upon installation generates an initial admin password which is stored in a Kubernetes secret. In order to retrieve this password, run the following command to decrypt the admin password:
 
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
 
Looking at the Argo CD dashboard, you would notice that an application has been created.

You can click on the `cluster-configuration` application to check the details of sync resources and their status on the cluster.

### Create Shop application

We are going to create the application `shop`, that we are going to use to test canary deployment. It is important to wait till **OpenShift Service Mesh** installation has finished, if not the Istio sidecar will not be injected in our applications.

```
oc apply -f canary-service-mesh/application-shop-mesh.yaml
```

Looking at the Argo CD dashboard, you would notice that we have a new `shop` application.


## Test Shop application
 
We have deployed the `shop` with ArgoCD. We can test that it is up and running.
 
We have to get the Istio gateway route.
```
oc get routes istio-ingressgateway -n istio-system --template='http://{{.spec.host}}/products'
```

TODO
## Delete environment
 
To delete all the things that we have done for the demo you have to:

- In GitHub delete the branch `mesh`
- In ArgoCD delete the application `cluster-configuration` and `shop`
- In Openshift, go to project `openshift-operators` and delete the installed operators **Openshift GitOps**, **OpenShift Service Mesh**, **Kiali Operator**, **OpenShift Elasticsearch Operator**, **Red Hat OpenShift distributed tracing platform**


