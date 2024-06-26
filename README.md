# Cloud Native Deployment Strategies

## Introduction
 
One important topic in the `Cloud Native` is the `Microservice Architecture`. We are no longer dealing with one monolithic application. We have several applications that have dependencies on each other and also have other dependencies like brokers or databases.
 
Applications have their own life cycle, so we should be able to execute independent deployment. All the applications and dependencies will not change their version at the same time.
 
Another important topic in the `Cloud Native` is the `Continuous Delivery`. If we are going to have several applications doing deployments independently we have to automate it. We will use **Helm**, **Openshift GitOps**, and of course **Red Hat Openshift** to help us.
 
**In this repository, we are going to test and compare different deployments strategies with `Cloud Native` applications. We will see real examples of how to install, deploy and manage the life cycle of `Cloud Native` applications using those strategies.**
 
## Deployment Strategies

Those are the different `Cloud Native` deployment strategies that we have developed, you can click on each one and test it.

- [**Blue/Green** using **Openshift Pipelines**](/blue-green-pipeline)
- [**Blue/Green** using **Argo Rollouts**](/blue-green-argo-rollouts)
- [**Canary** using **Openshift Service Mesh**](/canary-service-mesh)
- [**Canary** using **Argo Rollouts**](/canary-argo-rollouts)
- [**Canary** using **Argo Rollouts** and **Openshift Service Mesh**](/canary-argo-rollouts-service-mesh)



## Deployment Strategies comparison

Here is a comparison table of the advantages and disadvantages of each deployment strategy based on the provided articles:

| **Deployment Strategy** | **Advantages** | **Disadvantages** |
|-------------------------|----------------|--------------------|
| **Blue-Green Deployment with OpenShift Pipelines** | - **Minimal Downtime**: Near-instantaneous switch between environments reduces downtime.<br>- **Easy Rollback**: Immediate rollback capability if the new version fails.<br>- **Isolation**: Complete isolation of new version for thorough testing. | - **High Resource Cost**: Requires maintaining two identical environments, doubling infrastructure costs.<br>- **Complex Data Management**: Challenges in synchronizing databases across environments.<br>- **Configuration Complexity**: Requires significant setup and maintenance effort. |
| **Blue-Green Deployment with Argo Rollouts** | - **Flexible Traffic Management**: Allows for easy traffic redirection during deployment.<br>- **Rollback Capability**: Simplified rollback to previous version in case of issues.<br>- **Seamless Transition**: Users experience minimal interruption during deployment. | - **Configuration Complexity**: Requires careful configuration and maintenance.<br>- **Limited Traffic Management**: Does not offer fine-grained control over traffic distribution​   |
| **Canary Deployment with OpenShift Service Mesh** | - **Flexible Traffic Management**: Allows for easy traffic redirection during deployment.<br>- **Fine-Grained Control**: Offers detailed traffic management and performance monitoring.<br>- **Reduced Risk**: Identifies issues early with limited user impact. | - **Monitoring Requirement**: Requires continuous monitoring and analysis to manage rollout.<br>- **Complex Setup**: Traffic routing and management can be technically challenging. |
| **Canary Deployment with Argo Rollouts** | - **Flexible Traffic Management**: Allows for easy traffic redirection during deployment.<br>- **Rollback Capability**: Easily pauses and rolls back in case of issues.<br>- **Seamless Updates**: Minimizes user disruption by gradually introducing changes. | - **Increased Complexity**: Requires sophisticated traffic routing and monitoring tools.<br>- **Constant Monitoring Needed**: Demands continuous observation to detect and address issues.<br>- **Resource Overuse Potential**: Gradual rollouts can temporarily increase resource usage. |
| **Canary Deployment with Argo Rollouts and OpenShift Service Mesh** | - **Combined Strengths**: Leverages both tools for enhanced traffic management and observability.<br>- **Enhanced Observability**: Provides comprehensive monitoring capabilities.<br>- **Reduced Risk**: Combines incremental rollout with robust monitoring to minimize failure impact. | - **High Complexity**: Requires expertise in both tools for effective deployment and management.<br>- **Increased Monitoring**: Demands more extensive monitoring efforts.<br>- **Complex Setup**: Integration of multiple tools can complicate the deployment process. |

