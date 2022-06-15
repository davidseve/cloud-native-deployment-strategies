# Cloud Native Blue/Green

## OpenShift GitOps 
### Install OpenShift GitOps 

Log into OpenShift as a cluster admin and install the OpenShift GitOps operator with the following command:
```
oc apply -f gitops/gitops-operator.yaml
TODO ver si puedo meter aqui tambin la aplicaicon de argo y que todo sea solo este comando
```

Once OpenShift GitOps is installed, an instance of Argo CD is automatically installed on the cluster in the `openshift-gitops` namespace and link to this instance is added to the application launcher in OpenShift Web Console.

![Application Launcher](gitops/images/gitops-link.png)

### Log into Argo CD dashboard

Argo CD upon installation generates an initial admin password which is stored in a Kubernetes secret. In order to retrieve this password, run the following command to decrypt the admin password:

```
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
```

Click on Argo CD from the OpenShift Web Console application launcher and then log into Argo CD with `admin` username and the password retrieved from the previous step.

![Argo CD](gitops/images/ArgoCD-login.png)

![Argo CD](gitops/images/ArgoCD-UI.png)

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

![Argo CD - Applications](gitops/images/applications.png)

You can click on the **blue-green-cluster-configuration** application to check the details of sync resources and their status on the cluster. 

![Argo CD - Cluster Config](gitops/images/application-cluster-config-sync.png)


You can check that a namespace called `blue-green-gitops` is created on the cluster.

You can check that the **Openshift Pipelines operator** is installed.

And also the other to applications has been created **pipelines-blue-green** **shop-blue-green**


TODO poner como probar que shop funciona


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

TODO lanzar los pipelines

oc create -f 1-pipelinerun-products-new-version.yaml -n blue-green-gitops
oc create -f 2-pipelinerun-products-configuration.yaml -n blue-green-gitops
oc create -f 3-pipelinerun-products-scale-up.yaml -n blue-green-gitops
oc create -f 4-pipelinerun-products-switch.yaml -n blue-green-gitops












TODO borrar
borrar todas las aplicaciones desde la web de Argo
borra los operadoes de pipelienes y gitops desde la web de openshift

