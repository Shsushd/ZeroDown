# Troubleshooting Guide

Common issues and solutions for the Blue-Green deployment system.

## Table of Contents

1. [Docker Issues](#docker-issues)
2. [Kubernetes Issues](#kubernetes-issues)
3. [Pod Issues](#pod-issues)
4. [Service/Networking Issues](#servicenetworking-issues)
5. [Deployment Issues](#deployment-issues)
6. [HPA/Scaling Issues](#hpascaling-issues)
7. [Performance Issues](#performance-issues)

---

## Docker Issues

### Issue: "permission denied" when running Docker commands

**Symptoms:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes
newgrp docker

# Log out and back in, then verify
docker ps
```

---

### Issue: Docker daemon not starting

**Symptoms:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution:**
```bash
# Check Docker status
sudo systemctl status docker

# Start Docker
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# View logs if issues persist
sudo journalctl -u docker --no-pager | tail -50
```

---

### Issue: Image not found in minikube

**Symptoms:**
```
Failed to pull image "backend:v1": rpc error: code = NotFound
```

**Solution:**
```bash
# Verify image exists in Docker
docker images | grep backend

# Load into minikube
minikube image load backend:v1

# Verify in minikube
minikube image ls | grep backend

# Alternative: Set imagePullPolicy to Never
minikube kubectl -- edit deployment backend-blue
# Change: imagePullPolicy: IfNotPresent → Never
```

---

## Kubernetes Issues

### Issue: kubectl: command not found

**Symptoms:**
```
bash: kubectl: command not found
```

**Solution:**
```bash
# For minikube, minikube kubectl -- is included
# Verify minikube is running
minikube status

# minikube kubectl -- should be available after minikube start
minikube start

# If minikube kubectl -- still not found, use minikube kubectl --
minikube kubectl -- get pods

# Or create an alias
alias kubectl="minikube kubectl --"

# Verify
minikube kubectl -- version
```

---

### Issue: Unable to connect to the server

**Symptoms:**
```
The connection to the server localhost:8080 was refused
```

**Solution:**
```bash
# Check minikube is running
minikube status

# Start minikube if stopped
minikube start

# Verify connection
minikube kubectl -- cluster-info

# If issues persist, delete and recreate
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

---

### Issue: Metrics server not available

**Symptoms:**
```
error: Metrics API not available
```

**Solution:**
```bash
# Check if metrics-server exists
minikube kubectl -- get deployment metrics-server -n kube-system

# For k3s, it should be built-in
# If missing, install:
minikube kubectl -- apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For k3s, may need to add flags:
minikube kubectl -- edit deployment metrics-server -n kube-system
# Add: --kubelet-insecure-tls to args

# Wait and verify
minikube kubectl -- top nodes
```

---

## Pod Issues

### Issue: Pods stuck in "Pending" state

**Symptoms:**
```
NAME                          READY   STATUS    RESTARTS   AGE
backend-blue-xxxxxxxxx-xxxxx  0/1     Pending   0          5m
```

**Solution:**
```bash
# Describe pod to see reason
minikube kubectl -- describe pod <pod-name>

# Common causes and fixes:

# 1. Insufficient resources
minikube kubectl -- top nodes
# Scale down other deployments or add nodes

# 2. Image pull issues
# See "Image not found in k3s" above

# 3. Node selector mismatch
minikube kubectl -- get pod <pod-name> -o yaml | grep nodeSelector
# Remove or fix nodeSelector in deployment
```

---

### Issue: Pods in "CrashLoopBackOff"

**Symptoms:**
```
NAME                          READY   STATUS             RESTARTS   AGE
backend-blue-xxxxxxxxx-xxxxx  0/1     CrashLoopBackOff   5          10m
```

**Solution:**
```bash
# Check logs
minikube kubectl -- logs <pod-name>
minikube kubectl -- logs <pod-name> --previous  # Previous container logs

# Common causes:

# 1. Application error
# Fix code and rebuild image

# 2. Missing environment variables
minikube kubectl -- describe pod <pod-name> | grep -A 10 Environment

# 3. Port already in use
# Check port configuration in deployment

# 4. Wrong command/entrypoint
minikube kubectl -- get pod <pod-name> -o yaml | grep -A 5 command

# Force delete and recreate
minikube kubectl -- delete pod <pod-name>
```

---

### Issue: Pods not ready (readiness probe failing)

**Symptoms:**
```
NAME                          READY   STATUS    RESTARTS   AGE
backend-blue-xxxxxxxxx-xxxxx  0/1     Running   0          2m
```

**Solution:**
```bash
# Check events
minikube kubectl -- describe pod <pod-name> | grep -A 5 "Readiness probe failed"

# Check health endpoint
minikube kubectl -- port-forward <pod-name> 8080:3000
curl http://localhost:8080/health

# Common fixes:

# 1. Increase initialDelaySeconds
minikube kubectl -- edit deployment backend-blue
# Increase: initialDelaySeconds: 10

# 2. Check application logs
minikube kubectl -- logs <pod-name>

# 3. Verify health endpoint exists
# Update src/server.ts if needed
```

---

### Issue: "ImagePullBackOff" error

**Symptoms:**
```
NAME                          READY   STATUS             RESTARTS   AGE
backend-blue-xxxxxxxxx-xxxxx  0/1     ImagePullBackOff   0          3m
```

**Solution:**
```bash
# Describe pod for details
minikube kubectl -- describe pod <pod-name>

# For local images with k3s:
docker save backend:v1 -o /tmp/backend-v1.tar
sudo k3s ctr images import /tmp/backend-v1.tar

# Set imagePullPolicy
minikube kubectl -- patch deployment backend-blue -p '{"spec":{"template":{"spec":{"containers":[{"name":"backend","imagePullPolicy":"Never"}]}}}}'

# For registry authentication issues:
minikube kubectl -- create secret docker-registry regcred \
  --docker-server=<your-registry> \
  --docker-username=<username> \
  --docker-password=<password>

# Add to deployment
minikube kubectl -- patch deployment backend-blue -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}'
```

---

## Service/Networking Issues

### Issue: Service has no endpoints

**Symptoms:**
```
minikube kubectl -- get endpoints backend-service
NAME              ENDPOINTS
backend-service   <none>
```

**Solution:**
```bash
# Check service selector
minikube kubectl -- get service backend-service -o yaml | grep -A 2 selector

# Check pod labels
minikube kubectl -- get pods --show-labels

# Ensure labels match
# Service selector: app=backend, version=blue
# Pods must have: app=backend, version=blue

# Fix deployment labels if needed
minikube kubectl -- edit deployment backend-blue
```

---

### Issue: Cannot access service externally

**Symptoms:**
```
curl: (7) Failed to connect to <IP> port 80: Connection refused
```

**Solution:**
```bash
# Check service type
minikube kubectl -- get service backend-service

# For minikube, use minikube service command
minikube service backend-service --url

# Get URL and test
SERVICE_URL=$(minikube service backend-service --url)
curl $SERVICE_URL/

# Alternative: Use minikube tunnel (requires sudo)
# In separate terminal:
minikube tunnel

# Then access via LoadBalancer IP
minikube kubectl -- get service backend-service
curl http://<EXTERNAL-IP>/

# Or use port forwarding
minikube kubectl -- port-forward service/backend-service 8080:80
curl http://localhost:8080/
```

---

### Issue: Traffic not routing to new version

**Symptoms:**
```
# Switched to green but still getting v1 responses
curl http://localhost:$NODE_PORT/
Hello from Backend v1!
```

**Solution:**
```bash
# Verify service selector
minikube kubectl -- get service backend-service -o jsonpath='{.spec.selector}'

# Should show: {"app":"backend","version":"green"}

# If not correct, patch it
minikube kubectl -- patch service backend-service -p '{"spec":{"selector":{"version":"green"}}}'

# Check endpoints are correct
minikube kubectl -- get endpoints backend-service -o yaml

# Verify green pods are running
minikube kubectl -- get pods -l version=green

# Clear any connection caching
# Wait a few seconds and try again
```

---

## Deployment Issues

### Issue: Deployment rollout stuck

**Symptoms:**
```
minikube kubectl -- rollout status deployment/backend-green
Waiting for deployment "backend-green" rollout to finish: 1 of 2 updated replicas are available...
```

**Solution:**
```bash
# Check deployment events
minikube kubectl -- describe deployment backend-green

# Check pod status
minikube kubectl -- get pods -l app=backend,version=green

# Common causes:

# 1. Readiness probe failing
minikube kubectl -- describe pod <pod-name> | grep "Readiness"
# Increase initialDelaySeconds or fix health endpoint

# 2. Insufficient resources
minikube kubectl -- top nodes
minikube kubectl -- describe nodes

# 3. Image pull issues
# See ImagePullBackOff solutions above

# Force update
minikube kubectl -- rollout restart deployment/backend-green

# If stuck, delete and recreate
minikube kubectl -- delete deployment backend-green
minikube kubectl -- apply -f k8s/green-deployment.yaml
```

---

### Issue: Old pods not terminating

**Symptoms:**
```
minikube kubectl -- get pods
# Shows pods from old version still running
```

**Solution:**
```bash
# Check pod status
minikube kubectl -- get pods -l app=backend

# Graceful deletion
minikube kubectl -- delete pod <pod-name>

# Force deletion if stuck
minikube kubectl -- delete pod <pod-name> --grace-period=0 --force

# Check for finalizers
minikube kubectl -- get pod <pod-name> -o yaml | grep finalizers

# Remove finalizers if needed
minikube kubectl -- patch pod <pod-name> -p '{"metadata":{"finalizers":null}}'
```

---

## HPA/Scaling Issues

### Issue: HPA not scaling

**Symptoms:**
```
minikube kubectl -- get hpa backend-hpa
NAME          REFERENCE              TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
backend-hpa   Deployment/backend-blue   <unknown>/50%   2         10        2          10m
```

**Solution:**
```bash
# Check metrics-server
minikube kubectl -- get deployment metrics-server -n kube-system

# Verify metrics are available
minikube kubectl -- top nodes
minikube kubectl -- top pods

# Check HPA details
minikube kubectl -- describe hpa backend-hpa

# Common fixes:

# 1. Metrics server not running
minikube kubectl -- apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 2. Resource requests not set
minikube kubectl -- get deployment backend-blue -o yaml | grep -A 5 resources
# Ensure CPU/memory requests are defined

# 3. Not enough load
# Generate load to test
for i in {1..10000}; do curl http://localhost:$NODE_PORT/ > /dev/null 2>&1; done

# Watch HPA
minikube kubectl -- get hpa backend-hpa --watch
```

---

### Issue: HPA shows unknown metrics

**Symptoms:**
```
TARGETS    <unknown>/50%
```

**Solution:**
```bash
# Wait 1-2 minutes for metrics to populate

# Check if pods have resource requests
minikube kubectl -- get deployment backend-blue -o yaml | grep -A 10 resources

# If missing, add them:
minikube kubectl -- patch deployment backend-blue -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "backend",
          "resources": {
            "requests": {
              "cpu": "100m",
              "memory": "128Mi"
            }
          }
        }]
      }
    }
  }
}'

# Verify metrics-server
minikube kubectl -- logs -n kube-system deployment/metrics-server
```

---

## Performance Issues

### Issue: High CPU usage

**Symptoms:**
```
minikube kubectl -- top pods
NAME                          CPU(cores)   MEMORY(bytes)
backend-blue-xxxxxxxxx-xxxxx  450m         180Mi
```

**Solution:**
```bash
# Scale up immediately
minikube kubectl -- scale deployment/backend-blue --replicas=5

# Increase CPU limit
minikube kubectl -- edit deployment backend-blue
# Update: limits.cpu: "500m"

# Check application code for issues
minikube kubectl -- logs -f <pod-name>

# Profile application (if profiling enabled)
minikube kubectl -- port-forward <pod-name> 9229:9229
# Use Chrome DevTools or similar

# Long-term: optimize code or increase resources
```

---

### Issue: Out of memory (OOMKilled)

**Symptoms:**
```
NAME                          READY   STATUS      RESTARTS   AGE
backend-blue-xxxxxxxxx-xxxxx  0/1     OOMKilled   3          5m
```

**Solution:**
```bash
# Check memory usage
minikube kubectl -- top pods

# Describe pod for details
minikube kubectl -- describe pod <pod-name> | grep -A 5 "Last State"

# Immediate fix: increase memory limit
minikube kubectl -- patch deployment backend-blue -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "backend",
          "resources": {
            "limits": {
              "memory": "512Mi"
            }
          }
        }]
      }
    }
  }
}'

# Check for memory leaks in application
minikube kubectl -- logs <pod-name> --previous

# Monitor memory over time
watch minikube kubectl -- top pods
```

---

### Issue: Slow response times

**Symptoms:**
```
curl http://localhost:$NODE_PORT/
# Takes 5+ seconds to respond
```

**Solution:**
```bash
# Check pod logs for errors
minikube kubectl -- logs -f -l app=backend

# Check resource usage
minikube kubectl -- top pods

# Check if throttled
minikube kubectl -- describe pod <pod-name> | grep -i throttl

# Scale up
minikube kubectl -- scale deployment/backend-blue --replicas=5

# Check readiness probe isn't too aggressive
minikube kubectl -- get deployment backend-blue -o yaml | grep -A 10 readinessProbe

# Test directly to pod (bypass service)
POD_IP=$(minikube kubectl -- get pod <pod-name> -o jsonpath='{.status.podIP}')
minikube kubectl -- run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://$POD_IP:3000/
```

---

## General Debugging Commands

```bash
# Get everything
minikube kubectl -- get all -l app=backend

# Describe full deployment
minikube kubectl -- describe deployment backend-blue

# View all events
minikube kubectl -- get events --sort-by='.lastTimestamp'

# Check resource quotas
minikube kubectl -- describe resourcequota

# Check namespace limits
minikube kubectl -- describe limitrange

# Full pod YAML
minikube kubectl -- get pod <pod-name> -o yaml

# Check node conditions
minikube kubectl -- describe nodes

# Cluster info
minikube kubectl -- cluster-info
minikube kubectl -- cluster-info dump

# Minikube specific
minikube status
minikube logs
minikube ssh

# View all minikube images
minikube image ls
```

---

## Getting Help

If the issue persists:

1. **Gather information:**
   ```bash
   minikube kubectl -- get all -l app=backend > debug-info.txt
   minikube kubectl -- describe deployment backend-blue >> debug-info.txt
   minikube kubectl -- get events --sort-by='.lastTimestamp' >> debug-info.txt
   minikube kubectl -- logs <pod-name> >> debug-info.txt
   ```

2. **Check documentation:**
   - [README.md](../README.md)
   - [SETUP.md](../SETUP.md)
   - [DEPLOYMENT.md](../DEPLOYMENT.md)

3. **Search for similar issues:**
   - Kubernetes GitHub Issues
   - Stack Overflow
   - k3s discussions

4. **Community support:**
   - Kubernetes Slack
   - Reddit r/kubernetes
   - Server Fault

---

**Still stuck? Open an issue in the repository with the debug information!**
