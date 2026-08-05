# Container Orchestration - Microsoft Learn Resources

> **Curated Documentation**: Official documentation for Kubernetes, Azure Container Apps, and container orchestration patterns.

---

## Azure Kubernetes Service (AKS)

### Overview & QuickStart

- [What is Azure Kubernetes Service?](https://learn.microsoft.com/en-us/azure/aks/intro-kubernetes)
- [Quickstart: Deploy an AKS cluster](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli)
- [Kubernetes core concepts for AKS](https://learn.microsoft.com/en-us/azure/aks/concepts-clusters-workloads)
- [AKS baseline architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks/baseline-aks)

### Cluster Management

- [Create an AKS cluster](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-portal)
- [Scale an AKS cluster](https://learn.microsoft.com/en-us/azure/aks/scale-cluster)
- [Upgrade an AKS cluster](https://learn.microsoft.com/en-us/azure/aks/upgrade-cluster)
- [Node pools in AKS](https://learn.microsoft.com/en-us/azure/aks/use-multiple-node-pools)

### Networking

- [Network concepts for applications in AKS](https://learn.microsoft.com/en-us/azure/aks/concepts-network)
- [Configure Azure CNI networking](https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni)
- [Use an internal load balancer](https://learn.microsoft.com/en-us/azure/aks/internal-lb)
- [Application Gateway Ingress Controller](https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview)

### Storage

- [Storage options for applications in AKS](https://learn.microsoft.com/en-us/azure/aks/concepts-storage)
- [Dynamically create Azure disks](https://learn.microsoft.com/en-us/azure/aks/azure-disk-csi)
- [Dynamically create Azure Files](https://learn.microsoft.com/en-us/azure/aks/azure-files-dynamic-pv)
- [Use persistent volumes](https://learn.microsoft.com/en-us/azure/aks/concepts-storage#persistent-volumes)

### Security

- [Security concepts for AKS](https://learn.microsoft.com/en-us/azure/aks/concepts-security)
- [Use managed identities in AKS](https://learn.microsoft.com/en-us/azure/aks/use-managed-identity)
- [Use Azure AD integration](https://learn.microsoft.com/en-us/azure/aks/managed-aad)
- [Use Azure Key Vault with AKS](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)

### Best Practices

- [AKS best practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Cluster operator best practices](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-security)
- [Developer best practices](https://learn.microsoft.com/en-us/azure/aks/developer-best-practices-resource-management)
- [Multi-tenancy best practices](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-isolation)

---

## Azure Container Apps

### Overview & Getting Started

- [What is Azure Container Apps?](https://learn.microsoft.com/en-us/azure/container-apps/overview)
- [Quickstart: Deploy your first container app](https://learn.microsoft.com/en-us/azure/container-apps/quickstart-portal)
- [Container Apps environments](https://learn.microsoft.com/en-us/azure/container-apps/environment)
- [Compare Container Apps with other Azure container options](https://learn.microsoft.com/en-us/azure/container-apps/compare-options)

### Application Lifecycle

- [Deploy container apps](https://learn.microsoft.com/en-us/azure/container-apps/get-started)
- [Manage revisions](https://learn.microsoft.com/en-us/azure/container-apps/revisions)
- [Blue-green deployment](https://learn.microsoft.com/en-us/azure/container-apps/blue-green-deployment)
- [Update container apps](https://learn.microsoft.com/en-us/azure/container-apps/revisions-manage)

### Scalability

- [Scale a container app](https://learn.microsoft.com/en-us/azure/container-apps/scale-app)
- [Set scaling rules](https://learn.microsoft.com/en-us/azure/container-apps/scale-app#scale-rules)
- [KEDA scalers](https://learn.microsoft.com/en-us/azure/container-apps/scale-app#keda-scalers)
- [Scale to zero](https://learn.microsoft.com/en-us/azure/container-apps/scale-app#scale-to-zero)

### Networking & Ingress

- [Networking in Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/networking)
- [Configure ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview)
- [Set up custom domains](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates)
- [Enable CORS](https://learn.microsoft.com/en-us/azure/container-apps/cors)

### Dapr Integration

- [Dapr integration with Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/dapr-overview)
- [Enable Dapr](https://learn.microsoft.com/en-us/azure/container-apps/enable-dapr)
- [Use Dapr components](https://learn.microsoft.com/en-us/azure/container-apps/dapr-component-bindings)
- [Dapr pub/sub](https://learn.microsoft.com/en-us/azure/container-apps/dapr-publish-subscribe)

### Configuration & Secrets

- [Manage secrets](https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets)
- [Set environment variables](https://learn.microsoft.com/en-us/azure/container-apps/environment-variables)
- [Use Key Vault references](https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets#use-key-vault-references)

### Best Practices

- [Container Apps best practices](https://learn.microsoft.com/en-us/azure/container-apps/best-practices)
- [Reliability in Container Apps](https://learn.microsoft.com/en-us/azure/reliability/reliability-azure-container-apps)

---

## Kubernetes Fundamentals

### Core Concepts

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

### Configuration

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Managing Resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

### Storage

- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)

### Workloads

- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [DaemonSets](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

### Autoscaling

- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Vertical Pod Autoscaler](https://kubernetes.io/docs/tasks/autoscale-vertical-pod/)
- [Cluster Autoscaler](https://kubernetes.io/docs/concepts/cluster-administration/cluster-autoscaling/)

---

## Helm

### Getting Started

- [Helm Documentation](https://helm.sh/docs/)
- [Using Helm](https://helm.sh/docs/intro/using_helm/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Charts](https://helm.sh/docs/topics/charts/)

### Chart Development

- [Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Built-in Objects](https://helm.sh/docs/chart_template_guide/builtin_objects/)
- [Values Files](https://helm.sh/docs/chart_template_guide/values_files/)

### Chart Repository

- [Artifact Hub](https://artifacthub.io/)
- [Helm Chart Repository](https://helm.sh/docs/topics/chart_repository/)

---

## Docker & Docker Compose

### Docker Fundamentals

- [Docker Documentation](https://docs.docker.com/)
- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)

### Docker Compose

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Environment variables in Compose](https://docs.docker.com/compose/environment-variables/)

---

## Monitoring & Observability

### Azure Monitor

- [Monitor AKS](https://learn.microsoft.com/en-us/azure/aks/monitor-aks)
- [Container Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview)
- [Monitor Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/observability)

### Prometheus & Grafana

- [Prometheus on AKS](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/prometheus-metrics-enable)
- [Managed Prometheus](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/prometheus-metrics-overview)
- [Grafana](https://learn.microsoft.com/en-us/azure/managed-grafana/overview)

---

## CI/CD & DevOps

### Azure Pipelines

- [Build and deploy to AKS](https://learn.microsoft.com/en-us/azure/devops/pipelines/ecosystems/kubernetes/aks-template)
- [Deploy to Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/azure-pipelines)

### GitHub Actions

- [Deploy to AKS with GitHub Actions](https://learn.microsoft.com/en-us/azure/aks/kubernetes-action)
- [Deploy to Container Apps with GitHub Actions](https://learn.microsoft.com/en-us/azure/container-apps/github-actions-cli)

### GitOps

- [GitOps with Flux](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2)
- [GitOps for AKS](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gitops-aks/gitops-blueprint-aks)

---

## Security & Compliance

### AKS Security

- [Secure pod traffic with network policies](https://learn.microsoft.com/en-us/azure/aks/use-network-policies)
- [Pod security standards](https://learn.microsoft.com/en-us/azure/aks/use-pod-security-on-azure-policy)
- [Azure Policy for AKS](https://learn.microsoft.com/en-us/azure/aks/policy-reference)

### Container Security

- [Secure container images](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-best-practices)
- [Scan images for vulnerabilities](https://learn.microsoft.com/en-us/azure/container-registry/scan-with-defender)
- [Use managed identities](https://learn.microsoft.com/en-us/azure/aks/use-managed-identity)

---

## Cost Optimization

### AKS Cost Management

- [Plan and manage costs for AKS](https://learn.microsoft.com/en-us/azure/aks/cost-analysis)
- [Use spot node pools](https://learn.microsoft.com/en-us/azure/aks/spot-node-pool)
- [Optimize costs with autoscaling](https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler)

### Container Apps Pricing

- [Container Apps pricing](https://azure.microsoft.com/pricing/details/container-apps/)
- [Optimize Container Apps costs](https://learn.microsoft.com/en-us/azure/container-apps/scale-app#scale-to-zero)

---

## Migration & Modernization

### Containerization

- [Containerize applications](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/container-docker-introduction/)
- [Modernize with containers](https://learn.microsoft.com/en-us/azure/architecture/solution-ideas/articles/migrate-existing-applications-with-aks)

### Migration to AKS

- [Migrate to AKS](https://learn.microsoft.com/en-us/azure/aks/aks-migration)
- [Migrate from on-premises to AKS](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-migration/aks-migration)

---

## Additional Resources

### Learning Paths

- [AKS learning path](https://learn.microsoft.com/en-us/training/paths/intro-to-kubernetes-on-azure/)
- [Container Apps learning path](https://learn.microsoft.com/en-us/training/paths/deploy-applications-azure-container-apps/)
- [Kubernetes fundamentals](https://learn.microsoft.com/en-us/training/modules/intro-to-kubernetes/)

### Community & Tools

- [AKS GitHub repository](https://github.com/Azure/AKS)
- [Azure cli-aks-tool](https://github.com/Azure/azure-cli-extensions/tree/main/src/aks-preview)
- [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm charts repository](https://github.com/helm/charts)

### Reference Architectures

- [Microservices on AKS](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-microservices/aks-microservices)
- [AKS baseline for multiregion](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-multi-region/aks-multi-cluster)
- [Container Apps baseline](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/serverless/microservices-with-container-apps)
