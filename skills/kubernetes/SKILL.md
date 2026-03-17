---
name: kubernetes
description: Kubernetes manifest authoring, Helm chart patterns, and deployment configuration for production workloads. Covers Deployments, Services, Ingress, ConfigMaps, Secrets, resource limits, health probes, HPA, and k3s-specific considerations. Use when writing or reviewing Kubernetes manifests, setting up Helm charts, configuring deployments for production, or migrating from Docker Compose to Kubernetes.
---

# Kubernetes

This skill covers writing production-grade Kubernetes manifests and Helm charts. It assumes you understand what Kubernetes does — the focus is on doing it correctly.

## When to Use

- Writing Kubernetes manifests (Deployment, Service, Ingress, ConfigMap, Secret)
- Creating or reviewing a Helm chart for a service
- Configuring resource limits, health probes, or autoscaling
- Migrating from Docker Compose to Kubernetes or k3s
- Debugging a Pod that is CrashLooping or failing health checks

## When NOT to Use

- Containerizing the application itself — use `docker`
- CI/CD pipeline that deploys to Kubernetes — use `ci-cd`
- Infrastructure provisioning (cluster creation, cloud provider config) — different scope

## Core Principles

### Every Manifest is Production Configuration

A manifest that works in dev but lacks resource limits, health probes, or security context will cause production incidents. Apply production standards from the first manifest.

### Fail Fast, Recover Automatically

Kubernetes recovers from failures automatically — but only if health probes are configured correctly. A missing readiness probe means traffic is sent to pods that are not ready. A missing liveness probe means crashed pods are never restarted.

### Immutable Deployments

Never `kubectl exec` to modify a running container. Every change goes through a manifest update and a rollout. The running state must always be derivable from the manifests in the repository.

## Manifest Authoring Process

```
Kubernetes progress:
- [ ] Step 1: Define Deployment with resource limits and security context
- [ ] Step 2: Configure health probes (liveness + readiness)
- [ ] Step 3: Create Service and Ingress
- [ ] Step 4: Manage config and secrets
- [ ] Step 5: Configure autoscaling if needed
- [ ] Step 6: Verify rollout strategy
```

**Step 1: Deployment**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: document-service
  namespace: production
  labels:
    app: document-service
    version: "1.4.2"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: document-service
  template:
    metadata:
      labels:
        app: document-service
        version: "1.4.2"
    spec:
      # Security: non-root, read-only filesystem
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000

      containers:
        - name: document-service
          image: ghcr.io/myorg/document-service:abc1234  # always SHA, never latest
          ports:
            - containerPort: 3000

          # Resource limits — always set both requests and limits
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"

          # Container security
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]

          # Environment from ConfigMap and Secret
          envFrom:
            - configMapRef:
                name: document-service-config
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: document-service-secrets
                  key: database-url

          # Writable tmp for apps that need it
          volumeMounts:
            - name: tmp
              mountPath: /tmp

      volumes:
        - name: tmp
          emptyDir: {}

      # Graceful shutdown
      terminationGracePeriodSeconds: 30
```

Resource sizing guide:
- Start with `requests.cpu: 100m`, `requests.memory: 128Mi` and measure
- Set `limits.memory` to 2x the observed steady-state (never equal to requests for memory)
- Set `limits.cpu` to 2-5x requests — CPU throttling is recoverable, OOM kill is not
- Use `kubectl top pods` to see actual usage after a few hours of traffic

**Step 2: Health probes**

```yaml
livenessProbe:
  httpGet:
    path: /health      # liveness — is the process alive? No dependency checks.
    port: 3000
  initialDelaySeconds: 15   # time for app to start
  periodSeconds: 10
  failureThreshold: 3       # restart after 3 consecutive failures

readinessProbe:
  httpGet:
    path: /ready       # readiness — is the app ready for traffic?
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3       # remove from load balancer after 3 failures
  successThreshold: 1

startupProbe:
  httpGet:
    path: /health
    port: 3000
  failureThreshold: 30      # allow up to 5 minutes to start (30 * 10s)
  periodSeconds: 10
```

Use `startupProbe` for apps with slow startup (JVM, large Python apps) — prevents liveness probe from killing a slow-starting pod before it's ready.

**Step 3: Service and Ingress**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: document-service
  namespace: production
spec:
  selector:
    app: document-service
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP    # internal only — Ingress handles external traffic

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: document-service
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.example.com
      secretName: api-tls-cert
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /api/documents
            pathType: Prefix
            backend:
              service:
                name: document-service
                port:
                  number: 80
```

**Step 4: ConfigMap and Secrets**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: document-service-config
  namespace: production
data:
  NODE_ENV: "production"
  LOG_LEVEL: "info"
  QDRANT_HOST: "qdrant.production.svc.cluster.local"
  QDRANT_PORT: "6333"

---
# Secrets: base64 values (use Sealed Secrets or External Secrets in production)
apiVersion: v1
kind: Secret
metadata:
  name: document-service-secrets
  namespace: production
type: Opaque
stringData:                   # stringData auto-encodes to base64
  database-url: "postgresql://user:pass@db:5432/docs"
  jwt-secret: "..."
```

Secret management for production: never commit real secret values to git. Use:
- **Sealed Secrets** (kubeseal) — encrypt secrets with cluster public key, safe to commit
- **External Secrets Operator** — sync from Vault, AWS Secrets Manager, or similar
- **k3s**: `k3s secret` or External Secrets with local Vault

**Step 5: Horizontal Pod Autoscaler**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: document-service
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: document-service
  minReplicas: 2
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
```

HPA requires `requests` to be set on the container — it cannot calculate utilization percentage without a baseline.

**Step 6: Rollout strategy**

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1           # add 1 extra pod during rollout
    maxUnavailable: 0     # never remove pods before new ones are ready
```

`maxUnavailable: 0` ensures zero-downtime rollouts — new pods must become ready before old ones are terminated.

PodDisruptionBudget — prevents too many pods being down simultaneously:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: document-service-pdb
  namespace: production
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: document-service
```

## Helm Charts

Helm is the standard for packaging and configuring Kubernetes applications:

```
charts/document-service/
├── Chart.yaml
├── values.yaml           # default values
├── values-staging.yaml   # staging overrides
├── values-prod.yaml      # production overrides
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    ├── hpa.yaml
    └── _helpers.tpl      # shared template fragments
```

`Chart.yaml`:
```yaml
apiVersion: v2
name: document-service
version: 1.4.2
appVersion: "1.4.2"
description: Document management service
```

`values.yaml` — templatize everything that varies between environments:
```yaml
replicaCount: 2
image:
  repository: ghcr.io/myorg/document-service
  tag: "latest"           # override in CI with git SHA
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

ingress:
  enabled: true
  host: api.example.com

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
```

Deploy commands:
```bash
# Install
helm install document-service ./charts/document-service -f values-prod.yaml -n production

# Upgrade
helm upgrade document-service ./charts/document-service \
  -f values-prod.yaml \
  --set image.tag=abc1234 \
  -n production

# Diff before applying (with helm-diff plugin)
helm diff upgrade document-service ./charts/document-service -f values-prod.yaml -n production

# Rollback
helm rollback document-service 1 -n production
```

## k3s-Specific Patterns

k3s uses Traefik as the default ingress controller (not nginx):

```yaml
# k3s Traefik ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
```

k3s local path provisioner for persistent volumes:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: qdrant-data
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path   # k3s default
  resources:
    requests:
      storage: 10Gi
```

## Kubernetes Checklist

```
Deployment:
- [ ] Image tagged with SHA, not latest
- [ ] Resource requests AND limits set
- [ ] Security context: non-root, no privilege escalation
- [ ] readOnlyRootFilesystem: true (with tmp emptyDir if needed)

Health:
- [ ] livenessProbe configured (/health endpoint)
- [ ] readinessProbe configured (/ready endpoint)
- [ ] startupProbe for slow-starting apps

Networking:
- [ ] Service type is ClusterIP (not NodePort/LoadBalancer) for internal services
- [ ] Ingress configured with TLS
- [ ] Rate limiting on Ingress

Config:
- [ ] Non-sensitive config in ConfigMap
- [ ] Sensitive config in Secret (Sealed Secrets or External Secrets)
- [ ] No secrets in ConfigMap or Deployment env values

Reliability:
- [ ] replicas >= 2 in production
- [ ] RollingUpdate with maxUnavailable: 0
- [ ] PodDisruptionBudget defined
- [ ] HPA configured for variable-load services
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `image: myapp:latest` | `image: myapp:abc1234` — immutable SHA |
| No resource limits | Always set both requests and limits |
| `livenessProbe` hitting `/ready` (checks deps) | Liveness checks only process health (`/health`) |
| Secrets in ConfigMap or env literals | Sealed Secrets or External Secrets Operator |
| `replicas: 1` in production | `replicas: 2` minimum + PodDisruptionBudget |
| `maxUnavailable: 1` rolling update | `maxUnavailable: 0` for zero-downtime |
| `kubectl exec` to fix production | Fix in manifest, redeploy |

## Connected Skills

- `docker` — containerization precedes Kubernetes deployment
- `ci-cd` — Kubernetes deployment belongs in the CD pipeline
- `observability` — health probes connect to `/health` and `/ready` endpoints defined in observability skill
- `security-hardening` — security context, non-root user, read-only filesystem
