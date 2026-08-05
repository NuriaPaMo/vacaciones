# Container Orchestration - Code Examples

> **Progressive Disclosure**: These examples demonstrate container orchestration patterns across Kubernetes (AKS), Azure Container Apps, Docker Compose, and Helm.

---

## 1. Kubernetes Deployment - Basic Application (AKS)

**Scenario**: Deploy containerized application with replicas, health checks, and resource limits.

**File: deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-api
  namespace: production
  labels:
    app: myapp
    component: api
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
      component: api
  template:
    metadata:
      labels:
        app: myapp
        component: api
        version: v1.2.0
    spec:
      containers:
        - name: api
          image: myacr.azurecr.io/myapp-api:v1.2.0
          ports:
            - containerPort: 8080
              protocol: TCP
              name: http
          env:
            - name: ASPNETCORE_ENVIRONMENT
              value: 'Production'
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: myapp-secrets
                  key: database-url
            - name: APP_CONFIG_ENDPOINT
              valueFrom:
                configMapKeyRef:
                  name: myapp-config
                  key: app-config-endpoint
          resources:
            requests:
              cpu: '250m'
              memory: '512Mi'
            limits:
              cpu: '1000m'
              memory: '1Gi'
          livenessProbe:
            httpGet:
              path: /health/live
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health/ready
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
            timeoutSeconds: 2
            failureThreshold: 3
          startupProbe:
            httpGet:
              path: /health/startup
              port: http
            initialDelaySeconds: 0
            periodSeconds: 5
            failureThreshold: 30
      imagePullSecrets:
        - name: acr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-api-service
  namespace: production
spec:
  selector:
    app: myapp
    component: api
  ports:
    - protocol: TCP
      port: 80
      targetPort: http
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: 'letsencrypt-prod'
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.myapp.com
      secretName: myapp-tls
  rules:
    - host: api.myapp.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp-api-service
                port:
                  number: 80
```

**Deployment:**

```bash
# Apply manifests
kubectl apply -f deployment.yaml

# Check deployment status
kubectl rollout status deployment/myapp-api -n production

# Scale deployment
kubectl scale deployment/myapp-api --replicas=5 -n production

# Update image
kubectl set image deployment/myapp-api api=myacr.azurecr.io/myapp-api:v1.3.0 -n production

# Rollback deployment
kubectl rollout undo deployment/myapp-api -n production
```

---

## 2. Azure Container Apps - Bicep Deployment

**Scenario**: Serverless container platform with automatic scaling and built-in ingress.

**File: container-app.bicep**

```bicep
param location string = resourceGroup().location
param baseName string = 'myapp'
param environment string = 'prod'
param containerImage string
param containerRegistry string

var containerAppEnvName = '${baseName}-cae-${environment}'
var containerAppName = '${baseName}-api-${environment}'
var workspaceName = '${baseName}-law-${environment}'

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container Apps Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        corsPolicy: {
          allowedOrigins: ['https://myapp.com', 'https://www.myapp.com']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE']
          allowedHeaders: ['*']
          allowCredentials: true
        }
      }
      registries: [
        {
          server: containerRegistry
          identity: 'system'
        }
      ]
      secrets: [
        {
          name: 'database-url'
          value: 'Server=myserver.database.windows.net;Database=mydb;'
        }
      ]
      dapr: {
        enabled: true
        appId: 'myapp-api'
        appPort: 8080
        appProtocol: 'http'
      }
    }
    template: {
      revisionSuffix: 'v${uniqueString(containerImage)}'
      containers: [
        {
          name: 'api'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
            {
              name: 'DATABASE_URL'
              secretRef: 'database-url'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health/live'
                port: 8080
              }
              initialDelaySeconds: 15
              periodSeconds: 10
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health/ready'
                port: 8080
              }
              initialDelaySeconds: 5
              periodSeconds: 5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output managedIdentityPrincipalId string = containerApp.identity.principalId
```

**Deployment:**

```bash
# Deploy with Azure CLI
az deployment group create \
  --resource-group rg-myapp-prod \
  --template-file container-app.bicep \
  --parameters baseName=myapp environment=prod \
               containerImage=myacr.azurecr.io/myapp-api:latest \
               containerRegistry=myacr.azurecr.io

# View logs
az containerapp logs show \
  --name myapp-api-prod \
  --resource-group rg-myapp-prod \
  --follow

# Update container app
az containerapp update \
  --name myapp-api-prod \
  --resource-group rg-myapp-prod \
  --image myacr.azurecr.io/myapp-api:v1.3.0
```

---

## 3. Docker Compose - Multi-Service Local Development

**Scenario**: Local development environment with application, database, and cache.

**File: docker-compose.yml**

```yaml
version: '3.8'

services:
  api:
    build:
      context: ./src/Api
      dockerfile: Dockerfile
    image: myapp-api:local
    container_name: myapp-api
    ports:
      - '5000:8080'
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ASPNETCORE_URLS=http://+:8080
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=MyAppDb;User Id=sa;Password=${SA_PASSWORD};TrustServerCertificate=True;
      - ConnectionStrings__Redis=redis:6379
    depends_on:
      sqlserver:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - myapp-network
    volumes:
      - ./src/Api:/app
      - /app/bin
      - /app/obj
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:8080/health']
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s

  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: myapp-sqlserver
    environment:
      - ACCEPT_EULA=Y
      - MSSQL_SA_PASSWORD=${SA_PASSWORD}
      - MSSQL_PID=Developer
    ports:
      - '1433:1433'
    volumes:
      - sqlserver-data:/var/opt/mssql
    networks:
      - myapp-network
    healthcheck:
      test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT 1" || exit 1
      interval: 10s
      timeout: 3s
      retries: 10
      start_period: 10s

  redis:
    image: redis:7-alpine
    container_name: myapp-redis
    command: redis-server --appendonly yes
    ports:
      - '6379:6379'
    volumes:
      - redis-data:/data
    networks:
      - myapp-network
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 5s
      timeout: 3s
      retries: 5

  frontend:
    build:
      context: ./src/Frontend
      dockerfile: Dockerfile.dev
    image: myapp-frontend:local
    container_name: myapp-frontend
    ports:
      - '3000:3000'
    environment:
      - REACT_APP_API_URL=http://localhost:5000
    volumes:
      - ./src/Frontend:/app
      - /app/node_modules
    networks:
      - myapp-network
    depends_on:
      - api

volumes:
  sqlserver-data:
  redis-data:

networks:
  myapp-network:
    driver: bridge
```

**File: .env (Local Secrets)**

```env
SA_PASSWORD=YourStrong@Passw0rd
```

**Usage:**

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Restart service
docker-compose restart api

# Execute command in container
docker-compose exec api bash

# Stop and remove containers
docker-compose down

# Rebuild and start
docker-compose up -d --build
```

---

## 4. Kubernetes ConfigMap and Secret

**Scenario**: External configuration and sensitive data management.

**File: configmap.yaml**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: production
data:
  app-config-endpoint: 'https://myapp-appconfig.azconfig.io'
  log-level: 'Information'
  feature-flags: |
    {
      "BetaFeatures": false,
      "NewDashboard": true
    }
  appsettings.json: |
    {
      "AppSettings": {
        "ApiBaseUrl": "https://api.myapp.com",
        "CacheExpirationMinutes": 60,
        "MaxRetryAttempts": 3
      },
      "Logging": {
        "LogLevel": {
          "Default": "Information",
          "Microsoft.AspNetCore": "Warning"
        }
      }
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: production
type: Opaque
stringData:
  database-url: 'Server=myserver.database.windows.net;Database=mydb;User Id=appuser;Password=SecureP@ssw0rd;'
  api-key: 'super-secret-api-key-12345'
  jwt-signing-key: 'base64-encoded-key-here'
---
apiVersion: v1
kind: Secret
metadata:
  name: acr-secret
  namespace: production
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

**Deployment:**

```bash
# Create secret from file
kubectl create secret generic myapp-secrets \
  --from-literal=database-url="Server=..." \
  --from-literal=api-key="..." \
  --namespace=production

# Create secret for Azure Container Registry
kubectl create secret docker-registry acr-secret \
  --docker-server=myacr.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  --namespace=production

# Apply ConfigMap
kubectl apply -f configmap.yaml

# View ConfigMap
kubectl get configmap myapp-config -n production -o yaml

# Update ConfigMap
kubectl edit configmap myapp-config -n production
```

---

## 5. Helm Chart - Parameterized Kubernetes Deployment

**Scenario**: Reusable Kubernetes deployment with environment-specific values.

**File: Chart.yaml**

```yaml
apiVersion: v2
name: myapp
description: A Helm chart for MyApp
type: application
version: 1.0.0
appVersion: '1.2.0'
```

**File: values.yaml (Default Values)**

```yaml
replicaCount: 3

image:
  repository: myacr.azurecr.io/myapp-api
  tag: 'latest'
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: acr-secret

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: 'letsencrypt-prod'
  hosts:
    - host: api.myapp.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - api.myapp.com

resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

env:
  - name: ASPNETCORE_ENVIRONMENT
    value: 'Production'
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: myapp-secrets
        key: database-url

healthCheck:
  liveness:
    path: /health/live
    initialDelaySeconds: 30
    periodSeconds: 10
  readiness:
    path: /health/ready
    initialDelaySeconds: 10
    periodSeconds: 5
```

**File: templates/deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        env:
        {{- toYaml .Values.env | nindent 8 }}
        livenessProbe:
          httpGet:
            path: {{ .Values.healthCheck.liveness.path }}
            port: http
          initialDelaySeconds: {{ .Values.healthCheck.liveness.initialDelaySeconds }}
          periodSeconds: {{ .Values.healthCheck.liveness.periodSeconds }}
        readinessProbe:
          httpGet:
            path: {{ .Values.healthCheck.readiness.path }}
            port: http
          initialDelaySeconds: {{ .Values.healthCheck.readiness.initialDelaySeconds }}
          periodSeconds: {{ .Values.healthCheck.readiness.periodSeconds }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

**File: values-production.yaml (Production Overrides)**

```yaml
replicaCount: 5

image:
  tag: 'v1.2.0'

autoscaling:
  minReplicas: 5
  maxReplicas: 20

ingress:
  hosts:
    - host: api.myapp.com
      paths:
        - path: /
          pathType: Prefix

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi
```

**Deployment:**

```bash
# Install chart
helm install myapp ./myapp-chart \
  --namespace production \
  --create-namespace \
  --values values-production.yaml

# Upgrade chart
helm upgrade myapp ./myapp-chart \
  --namespace production \
  --values values-production.yaml

# Rollback
helm rollback myapp 1 --namespace production

# Uninstall
helm uninstall myapp --namespace production

# Template rendering (dry-run)
helm template myapp ./myapp-chart --values values-production.yaml
```

---

## 6. Kubernetes HorizontalPodAutoscaler (HPA)

**Scenario**: Automatic scaling based on CPU, memory, or custom metrics.

**File: hpa.yaml**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-api-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: '1000'
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
        - type: Pods
          value: 2
          periodSeconds: 60
      selectPolicy: Min
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 30
        - type: Pods
          value: 4
          periodSeconds: 30
      selectPolicy: Max
```

**Deployment:**

```bash
# Apply HPA
kubectl apply -f hpa.yaml

# Check HPA status
kubectl get hpa myapp-api-hpa -n production

# Watch HPA in real-time
kubectl get hpa myapp-api-hpa -n production --watch

# Describe HPA for detailed metrics
kubectl describe hpa myapp-api-hpa -n production
```

---

## 7. Kubernetes StatefulSet - Database with Persistent Storage

**Scenario**: Stateful workload requiring stable network identity and persistent volumes.

**File: statefulset.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: production
spec:
  ports:
    - port: 5432
      name: postgres
  clusterIP: None
  selector:
    app: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
spec:
  serviceName: postgres
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15-alpine
          ports:
            - containerPort: 5432
              name: postgres
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 2000m
              memory: 4Gi
          livenessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - pg_isready -U postgres
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - pg_isready -U postgres
            initialDelaySeconds: 5
            periodSeconds: 5
  volumeClaimTemplates:
    - metadata:
        name: postgres-storage
      spec:
        accessModes: ['ReadWriteOnce']
        storageClassName: 'managed-premium'
        resources:
          requests:
            storage: 100Gi
```

---

## 8. Azure Container Apps - KEDA Scaling with Azure Service Bus

**Scenario**: Event-driven scaling based on Azure Service Bus queue depth.

**File: container-app-keda.bicep**

```bicep
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'myapp-worker'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      secrets: [
        {
          name: 'servicebus-connectionstring'
          value: serviceBusConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'worker'
          image: 'myacr.azurecr.io/myapp-worker:latest'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 30
        rules: [
          {
            name: 'servicebus-scaling'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: 'workitems'
                messageCount: '10'
                namespace: 'myapp-sb'
              }
              auth: [
                {
                  secretRef: 'servicebus-connectionstring'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
}
```

---

## Summary

These examples demonstrate:

1. **Kubernetes Deployment** - Standard application deployment with health probes and resource limits
2. **Azure Container Apps** - Serverless containers with Dapr, automatic scaling, and ingress
3. **Docker Compose** - Multi-service local development environment
4. **Kubernetes ConfigMap/Secret** - External configuration and secret management
5. **Helm Chart** - Parameterized, reusable Kubernetes deployments
6. **HorizontalPodAutoscaler** - Automatic scaling based on metrics
7. **StatefulSet** - Stateful workloads with persistent storage
8. **KEDA Scaling** - Event-driven autoscaling with Azure Service Bus

All examples follow cloud-native best practices for security, observability, and scalability.
