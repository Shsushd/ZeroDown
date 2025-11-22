# Deployment Guide

Detailed guide for deploying and managing the Blue-Green deployment system.

## Table of Contents

1. [Deployment Strategies](#deployment-strategies)
2. [Blue-Green Deployment Process](#blue-green-deployment-process)
3. [Rollback Procedures](#rollback-procedures)
4. [Advanced Deployment Patterns](#advanced-deployment-patterns)
5. [Production Best Practices](#production-best-practices)
6. [Monitoring and Observability](#monitoring-and-observability)

---

## Deployment Strategies

### What is Blue-Green Deployment?

Blue-Green deployment is a release management strategy that reduces downtime and risk by running two identical production environments (Blue and Green):

- **Blue**: Currently running production version
- **Green**: New version ready to receive traffic

Traffic is switched instantly from Blue to Green, allowing immediate rollback if issues occur.

### Benefits

- **Zero-downtime deployments**: Users experience no interruption
- **Instant rollback**: Switch back to previous version in seconds
- **Easy testing**: Test new version in production-like environment
- **Disaster recovery**: Always have a working version ready

### Tradeoffs

- **Resource overhead**: Requires 2x infrastructure during deployment
- **Database complexity**: Schema changes must be backward compatible
- **Stateful applications**: Session management requires careful planning

---

## Blue-Green Deployment Process

### Step 1: Prepare New Version

#### 1.1 Update Application Code

```bash
# Make your code changes
vim src/server.ts

# Update version identifier
# Modify APP_VERSION in deployment YAML or rebuild with new tag
```

#### 1.2 Build Docker Image

```bash
# Build new version
docker build -t backend:v2 .

# Test locally
docker run -p 3000:3000 -e APP_VERSION=v2 backend:v2

# Test in browser/curl
curl http://localhost:3000/
curl http://localhost:3000/health
```

#### 1.3 Make Image Available to Kubernetes

**For Minikube:**
```bash
# Load image into minikube
minikube image load backend:v2

# Verify
minikube image ls | grep backend
```

**For Production (Registry):**
```bash
# Tag for registry
docker tag backend:v2 registry.example.com/backend:v2

# Push to registry
docker push registry.example.com/backend:v2

# Update deployment YAML to use registry image
```

### Step 2: Deploy New Version

#### 2.1 Update Deployment Manifest

Update the target deployment file (e.g., `k8s/green-deployment.yaml`):

```yaml
spec:
  template:
    spec:
      containers:
      - name: backend
        image: backend:v2  # ← Update version
        env:
        - name: APP_VERSION
          value: "v2"      # ← Update version
```

#### 2.2 Apply Deployment

```bash
# Deploy green version
minikube kubectl -- apply -f k8s/green-deployment.yaml

# Watch the rollout
minikube kubectl -- rollout status deployment/backend-green
```

#### 2.3 Verify Pods are Running

```bash
# Check pod status
minikube kubectl -- get pods -l version=green

# View logs
minikube kubectl -- logs -l version=green --tail=50

# Check readiness
minikube kubectl -- get pods -l version=green -o wide
```

### Step 3: Test New Version

Before switching traffic, thoroughly test the new version:

#### 3.1 Port-Forward to Test

```bash
# Port forward to green deployment
minikube kubectl -- port-forward deployment/backend-green 8080:3000

# Test in another terminal
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/version

# Run integration tests
npm run test:integration  # if you have tests
```

#### 3.2 Create Temporary Test Service (Optional)

```bash
# Create a test service
cat <<EOF | minikube kubectl -- apply -f -
apiVersion: v1
kind: Service
metadata:
  name: backend-green-test
spec:
  selector:
    app: backend
    version: green
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: NodePort
EOF

# Get NodePort and test
minikube kubectl -- get service backend-green-test
curl http://localhost:<NodePort>/
```

### Step 4: Switch Traffic

#### 4.1 Using the Deploy Script

```bash
# Automated switch
./deploy.sh green
```

The script performs:
1. Deploys the version (if not already deployed)
2. Waits for readiness
3. Switches the service selector
4. Confirms success

#### 4.2 Manual Traffic Switch

```bash
# Patch service to point to green
minikube kubectl -- patch service backend-service -p '{"spec":{"selector":{"version":"green"}}}'

# Verify the change
minikube kubectl -- get service backend-service -o yaml | grep -A 2 selector
```

### Step 5: Monitor New Version

```bash
# Watch pods
minikube kubectl -- get pods -w

# View logs
minikube kubectl -- logs -f -l version=green

# Check HPA
minikube kubectl -- get hpa backend-hpa

# Monitor metrics (if Prometheus is installed)
# Check error rates, response times, etc.
```

### Step 6: Cleanup or Retain Old Version

**Option A: Keep for Quick Rollback (Recommended)**
```bash
# Leave blue deployment running
# No action needed
```

**Option B: Scale Down to Save Resources**
```bash
# Scale down to 0 replicas
minikube kubectl -- scale deployment/backend-blue --replicas=0
```

**Option C: Delete Old Version**
```bash
# Only if confident in new version
minikube kubectl -- delete deployment/backend-blue

# Can always recreate from YAML if needed
```

---

## Rollback Procedures

### Instant Rollback

If issues are detected, immediately revert traffic:

```bash
# Switch back to blue
./deploy.sh blue

# Or manually
minikube kubectl -- patch service backend-service -p '{"spec":{"selector":{"version":"blue"}}}'
```

### Rollback with Kubernetes Native Tools

```bash
# View deployment history
minikube kubectl -- rollout history deployment/backend-green

# Rollback to previous version
minikube kubectl -- rollout undo deployment/backend-green

# Rollback to specific revision
minikube kubectl -- rollout undo deployment/backend-green --to-revision=2
```

### Emergency Rollback Checklist

- [ ] Identify the issue quickly
- [ ] Switch traffic to stable version
- [ ] Verify traffic is routed correctly
- [ ] Monitor error rates
- [ ] Scale up old version if needed
- [ ] Investigate root cause
- [ ] Document incident

---

## Advanced Deployment Patterns

### Canary Deployment

Gradually shift traffic to test new version with subset of users:

```yaml
# Create separate services for weight-based routing
# Requires Ingress controller like NGINX or Istio

# Example with Istio VirtualService:
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  hosts:
  - backend.example.com
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: backend-green
      weight: 100
  - route:
    - destination:
        host: backend-blue
      weight: 90
    - destination:
        host: backend-green
      weight: 10
```

### A/B Testing

Route specific users to different versions:

```yaml
# Route based on user headers, cookies, or IP
# Example: Route users with specific header to green

apiVersion: v1
kind: Service
metadata:
  name: backend-service-ab
spec:
  selector:
    app: backend
    # Use Ingress rules for A/B logic
  ports:
  - port: 80
    targetPort: 3000
```

### Database Migration Strategy

> [!CAUTION]
> Database schema changes require careful planning to avoid breaking deployments.

#### Backward Compatible Migration Pattern

**Phase 1: Add New Column (Deploy v1.1)**
```sql
-- Add nullable column
ALTER TABLE users ADD COLUMN email VARCHAR(255);
```

**Phase 2: Dual Write (Deploy v2)**
```javascript
// Write to both old and new fields
user.username = username;
user.email = email;  // Also write to new field
```

**Phase 3: Backfill Data**
```sql
-- Migrate existing data
UPDATE users SET email = username WHERE email IS NULL;
```

**Phase 4: Read from New Field (Deploy v3)**
```javascript
// Start reading from new field
const email = user.email;
```

**Phase 5: Cleanup (Deploy v4)**
```sql
-- Remove old column
ALTER TABLE users DROP COLUMN username;
```

---

## Production Best Practices

### 1. Health Checks

Ensure proper health endpoints:

```typescript
// Readiness: Can the pod serve traffic?
app.get('/health/ready', (req, res) => {
  // Check database connections, dependencies
  if (database.isConnected() && cache.isReady()) {
    res.status(200).json({ status: 'ready' });
  } else {
    res.status(503).json({ status: 'not ready' });
  }
});

// Liveness: Is the pod alive?
app.get('/health/live', (req, res) => {
  // Basic health check
  res.status(200).json({ status: 'alive' });
});
```

### 2. Graceful Shutdown

Handle termination signals properly:

```typescript
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    // Close database connections, etc.
    process.exit(0);
  });
});
```

### 3. Resource Management

Set appropriate resource limits:

```yaml
resources:
  requests:
    cpu: "100m"      # Minimum guaranteed
    memory: "128Mi"
  limits:
    cpu: "500m"      # Maximum allowed
    memory: "512Mi"
```

### 4. Auto-scaling Configuration

Tune HPA for your traffic patterns:

```yaml
spec:
  minReplicas: 3           # Minimum for HA
  maxReplicas: 20          # Adjust based on capacity
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Scale at 70% CPU
```

### 5. Security

- Use non-root container users
- Enable Pod Security Policies/Standards
- Scan images for vulnerabilities
- Use secrets for sensitive data
- Enable network policies

### 6. Monitoring

Essential metrics to track:

- **Request rate**: Requests per second
- **Error rate**: 4xx and 5xx responses
- **Latency**: P50, P95, P99 response times
- **Saturation**: CPU, memory, disk usage
- **Availability**: Uptime percentage

---

## Monitoring and Observability

### Kubernetes Native Monitoring

```bash
# Resource usage
minikube kubectl -- top nodes
minikube kubectl -- top pods

# Events
minikube kubectl -- get events --sort-by='.lastTimestamp'

# Logs
minikube kubectl -- logs -f deployment/backend-green --all-containers=true

# Pod details
minikube kubectl -- describe pod <pod-name>
```

### Prometheus & Grafana Setup (Advanced)

```bash
# Install Prometheus Operator
minikube kubectl -- apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml

# Install kube-prometheus stack (includes Grafana)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

# Access Grafana
minikube kubectl -- port-forward svc/prometheus-grafana 3000:80
# Login: admin / prom-operator
```

### Application Metrics

Add Prometheus metrics to your application:

```typescript
import promClient from 'prom-client';

// Create a Registry
const register = new promClient.Registry();

// Metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

---

## Deployment Checklist

Use this checklist before each deployment:

### Pre-Deployment
- [ ] Code reviewed and approved
- [ ] Tests passing (unit, integration, e2e)
- [ ] Docker image built and tagged
- [ ] Image scanned for vulnerabilities
- [ ] Database migrations prepared (if any)
- [ ] Deployment manifest updated
- [ ] Rollback plan documented

### Deployment
- [ ] Deploy to staging/test environment first
- [ ] Run smoke tests
- [ ] Deploy to production (inactive slot)
- [ ] Verify health checks passing
- [ ] Run integration tests against new version
- [ ] Monitor resource usage

### Traffic Switch
- [ ] Switch traffic to new version
- [ ] Monitor error rates
- [ ] Monitor latency
- [ ] Check logs for errors
- [ ] Verify business metrics

### Post-Deployment
- [ ] Monitor for 30-60 minutes
- [ ] Run synthetic tests
- [ ] Check user-facing metrics
- [ ] Document any issues
- [ ] Clean up or retain old version

---

## Useful Commands Reference

```bash
# Quick deployment
./deploy.sh green

# Manual deployment steps
minikube kubectl -- apply -f k8s/green-deployment.yaml
minikube kubectl -- rollout status deployment/backend-green
minikube kubectl -- patch service backend-service -p '{"spec":{"selector":{"version":"green"}}}'

# Monitoring
minikube kubectl -- get pods -w
minikube kubectl -- logs -f deployment/backend-green
minikube kubectl -- top pods

# Rollback
minikube kubectl -- patch service backend-service -p '{"spec":{"selector":{"version":"blue"}}}'

# Scaling
minikube kubectl -- scale deployment/backend-green --replicas=5

# Cleanup
minikube kubectl -- delete deployment/backend-blue
```

---

## Summary

You now have a complete understanding of Blue-Green deployments!

**Key Takeaways:**
- Blue-Green enables zero-downtime deployments
- Always test thoroughly before switching traffic
- Keep old version running for quick rollback
- Monitor closely after traffic switch
- Plan database changes carefully
- Automate the process for consistency

For more information, see:
- [README.md](README.md) - Project overview
- [SETUP.md](SETUP.md) - Initial setup guide
