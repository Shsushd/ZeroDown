# Quick Reference Guide

Essential commands and workflows for the Blue-Green deployment system.

## Quick Start

```bash
# Install dependencies
npm install

# Build application
npm run build

# Build Docker images
docker build -t backend:v1 .
docker build -t backend:v2 .

# Load into minikube
minikube image load backend:v1
minikube image load backend:v2

# Deploy to Kubernetes
minikube kubectl -- apply -f k8s/service.yaml
minikube kubectl -- apply -f k8s/blue-deployment.yaml
minikube kubectl -- apply -f k8s/green-deployment.yaml
minikube kubectl -- apply -f k8s/hpa.yaml
```

## Essential Commands

### Deployment

```bash
# Switch to blue version
./deploy.sh blue

# Switch to green version
./deploy.sh green

# Manual traffic switch
minikube kubectl -- patch service backend-service -p '{"spec":{"selector":{"version":"blue"}}}'
minikube kubectl -- patch service backend-service -p '{"spec":{"selector":{"version":"green"}}}'
```

### Monitoring

```bash
# View all resources
minikube kubectl -- get all -l app=backend

# Watch pods
minikube kubectl -- get pods -w

# View logs (follow)
minikube kubectl -- logs -f -l app=backend

# View logs for specific version
minikube kubectl -- logs -f -l version=blue
minikube kubectl -- logs -f -l version=green

# Check service
minikube kubectl -- get service backend-service

# Check HPA
minikube kubectl -- get hpa backend-hpa

# Resource usage
minikube kubectl -- top nodes
minikube kubectl -- top pods
```

### Testing

```bash
# Get NodePort
NODE_PORT=$(minikube kubectl -- get service backend-service -o jsonpath='{.spec.ports[0].nodePort}')

# Get service URL (minikube)
SERVICE_URL=$(minikube service backend-service --url)

# Test endpoints
curl $SERVICE_URL/
curl $SERVICE_URL/version
curl $SERVICE_URL/health

# Port forward
minikube kubectl -- port-forward service/backend-service 8080:80

# Test with port forward
curl http://localhost:8080/
```

### Scaling

```bash
# Scale deployment
minikube kubectl -- scale deployment/backend-blue --replicas=5

# Update HPA
minikube kubectl -- edit hpa backend-hpa

# View HPA events
minikube kubectl -- describe hpa backend-hpa
```

### Troubleshooting

```bash
# Describe pod (shows events)
minikube kubectl -- describe pod <pod-name>

# View recent events
minikube kubectl -- get events --sort-by='.lastTimestamp'

# Check pod status
minikube kubectl -- get pods -o wide

# Check endpoints
minikube kubectl -- get endpoints backend-service

# Exec into pod
minikube kubectl -- exec -it <pod-name> -- sh

# View pod YAML
minikube kubectl -- get pod <pod-name> -o yaml
```

## Docker Commands

```bash
# Build image
docker build -t backend:v1 .

# Run locally
docker run -p 3000:3000 -e APP_VERSION=v1 backend:v1

# List images
docker images

# Remove image
docker rmi backend:v1

# Load into minikube
minikube image load backend:v1

# List minikube images
minikube image ls | grep backend

# Remove from minikube
minikube image rm backend:v1
```

## Kubernetes Manifests Quick Edit

```bash
# Edit deployment
minikube kubectl -- edit deployment backend-blue

# Edit service
minikube kubectl -- edit service backend-service

# Edit HPA
minikube kubectl -- edit hpa backend-hpa

# Apply changes
minikube kubectl -- apply -f k8s/blue-deployment.yaml
```

## Common Workflows

### Deploy New Version

```bash
# 1. Update code
nano src/server.ts

# 2. Build
npm run build

# 3. Build Docker image
docker build -t backend:v2 .

# 4. Load into minikube
minikube image load backend:v2

# 5. Deploy
minikube kubectl -- apply -f k8s/green-deployment.yaml

# 6. Wait for ready
minikube kubectl -- rollout status deployment/backend-green

# 7. Test
minikube kubectl -- port-forward deployment/backend-green 8080:3000
curl http://localhost:8080/

# 8. Switch traffic
./deploy.sh green

# 9. Monitor
minikube kubectl -- logs -f -l version=green
```

### Rollback

```bash
# Instant switch
./deploy.sh blue

# Or manual
minikube kubectl -- patch service backend-service -p '{"spec":{"selector":{"version":"blue"}}}'

# Verify
minikube kubectl -- get service backend-service -o yaml | grep -A 2 selector
```

### Update Resources

```bash
# Scale up for traffic spike
minikube kubectl -- scale deployment/backend-blue --replicas=10

# Update resource limits
minikube kubectl -- edit deployment backend-blue
# Modify resources section, save

# Verify rollout
minikube kubectl -- rollout status deployment/backend-blue
```

### Debug Pod Issues

```bash
# 1. Check status
minikube kubectl -- get pods

# 2. Describe problematic pod
minikube kubectl -- describe pod <pod-name>

# 3. Check logs
minikube kubectl -- logs <pod-name>

# 4. Previous container logs (if crashed)
minikube kubectl -- logs <pod-name> --previous

# 5. Exec into pod (if running)
minikube kubectl -- exec -it <pod-name> -- sh

# 6. Check events
minikube kubectl -- get events --field-selector involvedObject.name=<pod-name>
```

## Health Check Endpoints

| Endpoint   | Purpose       | Expected Response                |
| ---------- | ------------- | -------------------------------- |
| `/`        | Main endpoint | `Hello from Backend v1!`         |
| `/version` | Version info  | `{"version":"v1"}`               |
| `/health`  | Health check  | `{"status":"ok","version":"v1"}` |

## Service Selector States

| State | Selector         | Active Deployment | Description         |
| ----- | ---------------- | ----------------- | ------------------- |
| Blue  | `version: blue`  | backend-blue      | Production on blue  |
| Green | `version: green` | backend-green     | Production on green |

View current state:

```bash
minikube kubectl -- get service backend-service -o jsonpath='{.spec.selector}'
```

## Configuration Files

| File                        | Purpose                  |
| --------------------------- | ------------------------ |
| `src/server.ts`             | Application code         |
| `Dockerfile`                | Container build          |
| `package.json`              | Dependencies             |
| `tsconfig.json`             | TypeScript config        |
| `k8s/service.yaml`          | LoadBalancer service     |
| `k8s/blue-deployment.yaml`  | Blue version deployment  |
| `k8s/green-deployment.yaml` | Green version deployment |
| `k8s/hpa.yaml`              | Auto-scaler config       |
| `deploy.sh`                 | Deployment script        |

## Default Resource Allocations

### Per Pod

- **CPU Request**: 100m (0.1 cores)
- **CPU Limit**: 200m (0.2 cores)
- **Memory Request**: 128Mi
- **Memory Limit**: 256Mi

### HPA Settings

- **Min Replicas**: 2
- **Max Replicas**: 10
- **CPU Target**: 50% utilization

## Environment Variables

| Variable      | Default | Description        |
| ------------- | ------- | ------------------ |
| `PORT`        | 3000    | Server port        |
| `APP_VERSION` | v1      | Version identifier |

Set in deployment YAML:

```yaml
env:
  - name: APP_VERSION
    value: "v1"
```

## Emergency Procedures

### Complete System Down

```bash
# Check cluster
minikube kubectl -- get nodes

# Check all pods
minikube kubectl -- get pods --all-namespaces

# Restart deployments
minikube kubectl -- rollout restart deployment/backend-blue
minikube kubectl -- rollout restart deployment/backend-green
```

### High CPU/Memory

```bash
# Check resource usage
minikube kubectl -- top pods

# Scale deployment
minikube kubectl -- scale deployment/backend-blue --replicas=5

# Check HPA
minikube kubectl -- get hpa backend-hpa
```

### Database Connection Issues

```bash
# Check pod logs
minikube kubectl -- logs -f -l app=backend | grep -i error

# Restart deployment
minikube kubectl -- rollout restart deployment/backend-blue
```

## Pro Tips

1. **Always test before switching traffic**

   ```bash
   minikube kubectl -- port-forward deployment/backend-green 8080:3000
   ```

2. **Keep old version running for quick rollback**

   ```bash
   # Don't delete immediately after switch
   ```

3. **Monitor after traffic switch**

   ```bash
   minikube kubectl -- logs -f -l app=backend
   minikube kubectl -- get hpa backend-hpa --watch
   ```

4. **Use labels for better organization**

   ```bash
   minikube kubectl -- get pods -l app=backend,version=blue
   ```

5. **Save often-used commands as aliases**
   ```bash
   alias k='minikube kubectl --'
   alias kgp='minikube kubectl -- get pods'
   alias kgs='minikube kubectl -- get service'
   alias kl='minikube kubectl -- logs -f'
   ```

## Quick Links

- **[README.md](README.md)** - Project overview
- **[SETUP.md](SETUP.md)** - Complete Ubuntu setup guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Detailed deployment guide

---

**Print this page for quick reference during deployments!**
