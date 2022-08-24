# Cloud Native Deployment Strategies

| :warning: WARNING          |
|:---------------------------|
| Work in progress           |

## Introduction
 
One important topic in the `Cloud Native` is the `Microservice Architecture`. We are not any more dealing with one monolithic application. We have several applications that have dependencies on each other and also have other dependencies like brokers or data bases.
 
Applications have their own life cycle, so we should be able to execute independent deployment. All the applications and dependencies will not change its version at the same time.
 
Another important topic in the `Cloud Native` is the `Continuous Delivery`. If we are going to have several applications doing deployments independently we have to automate it. We will use **Helm**, **Openshift GitOps** and of course **Red Hat Openshift** to help us.
 
**In this repository we are going to test and compare different deployments strategies with `Cloud Native` applications. We will see real examples of how to install, deploy and manage the life cycle of `Cloud Native` applications using those strategies.**
 
## Deployment Strategies

Those are the different `Cloud Native` deployment strategies that we have developed, you can click on each one and test it.

- [**Blue/Green** using **Openshift Pipelines**](/blue-green-pipeline)
- [**Blue/Green** using **Argo Rollouts**](/blue-green-argo-rollouts)
- [**Canary** using **Argo Rollouts**](/canary-argo-rollouts)
- [**Canary** using **Openshift Service Mesh** (Work in progress)](/canary-service-mesh)
- [**Canary** using **Argo Rollouts** and **Openshift Service Mesh** (Work in progress)](/canary-rollouts-service-mesh)



Those are the advantages and disadvantages of all of those deployment strategies:

Advantages:
- Minimize downtime
- Rapid way to rollback
 
Disadvantages:
- Backwards compatibility

## Deployment Strategies comparison

This is the comparison between the different strategy:

| Name                                  | Advantage | Disadvantage |
| ------------------------------------- | --------- | ------------ |
| Blue/Green Openshift Pipelines        |           |              |
| Blue/Green Argo Rollouts              |           |              |
| Canary Argo Rollouts                  |           |              |
| Canary Service Mesh                   |           |              |
| Canary Argo Rollouts and Service Mesh |           |              |



