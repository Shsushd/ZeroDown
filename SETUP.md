# Complete Setup Guide for Ubuntu Server

This guide walks you through setting up the Blue-Green Deployment PoC from a **pure vanilla Ubuntu server** (Ubuntu 20.04 LTS or later).

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Initial Server Setup](#initial-server-setup)
3. [Install Docker](#install-docker)
4. [Install Minikube](#install-minikube)
5. [Install Node.js](#install-nodejs)
6. [Setup Project](#setup-project)
7. [Build and Deploy](#build-and-deploy)
8. [Verify Installation](#verify-installation)
9. [Next Steps](#next-steps)

---

## System Requirements

### Minimum Hardware

- **CPU**: 2 cores
- **RAM**: 4GB (8GB recommended)
- **Disk**: 20GB free space
- **Network**: Internet connection for package downloads

### Software

- **OS**: Ubuntu 20.04 LTS or later (64-bit)
- **User**: sudo/root access required

---

## Initial Server Setup

### 1. Update System Packages

```bash
# Update package lists
sudo apt update

# Upgrade installed packages
sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git vim software-properties-common apt-transport-https ca-certificates gnupg lsb-release
```

### 2. Configure Firewall (Optional but Recommended)

```bash
# If using UFW (Uncomplicated Firewall)
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS

# Note: Minikube runs in a VM/container, so most ports are handled internally
# Enable firewall (be careful with SSH access)
# sudo ufw enable
```

---

## Install Docker

### 1. Remove Old Docker Versions (if any)

```bash
sudo apt remove -y docker docker-engine docker.io containerd runc
```

### 2. Install Docker

```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 3. Configure Docker Permissions

```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Apply group changes (log out and back in, or run):
newgrp docker

# Verify Docker installation
docker --version
docker run hello-world
```

### 4. Configure Docker Daemon (Optional)

```bash
# Create daemon configuration
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Restart Docker
sudo systemctl restart docker
sudo systemctl enable docker
```

---

## Install Minikube

**Minikube** is a lightweight Kubernetes distribution that runs in a virtual machine or container, perfect for local development and testing.

### 1. Install Minikube

```bash
# Download the latest minikube binary
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Remove the downloaded file
rm minikube-linux-amd64

# Verify installation
minikube version
```

### 2. Start Minikube

```bash
# Start minikube with Docker driver
minikube start --driver=docker --cpus=2 --memory=4096

# Wait for minikube to start (this may take a few minutes on first run)
# You should see: "Done! minikube kubectl -- is now configured to use "minikube" cluster"

# Verify cluster is running
minikube status

# Expected output:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured
```

### 3. Configure kubectl

minikube kubectl -- is automatically installed and configured with minikube:

```bash
# Verify minikube kubectl -- is working


# Check cluster info
minikube kubectl -- cluster-info

# Check nodes
minikube kubectl -- get nodes

# You should see one node named "minikube" in "Ready" status
```

### 4. Enable Minikube Addons

```bash
# Enable metrics-server for HPA (Horizontal Pod Autoscaler)
minikube addons enable metrics-server

# Verify metrics-server is running
minikube kubectl -- get deployment metrics-server -n kube-system

# Optional: Enable other useful addons
minikube addons enable dashboard       # Kubernetes dashboard
minikube addons enable ingress        # Ingress controller (if needed)

# List all available addons
minikube addons list
```

### 5. Verify Minikube Installation

```bash
# Check all system pods are running
minikube kubectl -- get pods -A

# All pods should be in "Running" status

# Test metrics (may take 1-2 minutes after enabling)
minikube kubectl -- top nodes

# If metrics aren't ready yet, you'll see:
# "error: Metrics API not available"
# Wait a minute and try again
```

### Minikube Useful Commands

```bash
# Stop minikube (preserves cluster state)
minikube stop

# Start minikube again
minikube start

# Delete minikube cluster (removes everything)
minikube delete

# SSH into minikube node
minikube ssh

# View minikube dashboard
minikube dashboard

# Get minikube IP
minikube ip

# View minikube logs
minikube logs
```

---

## Install Node.js

### 1. Install Node.js 18.x LTS

```bash
# Install NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version    # Should show v18.x.x
npm --version     # Should show 9.x.x or later
```

### 2. Update npm (Optional)

```bash
# Update to latest npm
sudo npm install -g npm@latest
```

---

## Setup Project

### 1. Clone or Create Project Directory

```bash
# If cloning from a repository
git clone <your-repository-url> ~/kurbentes
cd ~/kurbentes

# Or if copying files to server
mkdir -p ~/kurbentes
cd ~/kurbentes
# Upload/copy your project files here
```

### 2. Install Project Dependencies

```bash
# Install npm packages
npm install

# This will install:
# - express (runtime dependency)
# - TypeScript and type definitions (dev dependencies)
```

### 3. Build the Application

```bash
# Compile TypeScript to JavaScript
npm run build

# Verify build output
ls -la dist/
# You should see server.js
```

---

## Build and Deploy

### 1. Build Docker Images

```bash
# Build version 1 (Blue)
docker build -t backend:v1 .

# Build version 2 (Green) - modify APP_VERSION if needed
docker build -t backend:v2 .

# Verify images
docker images | grep backend
```

### 2. Import Images to Minikube

Minikube can load Docker images directly:

```bash
# Load images into minikube
minikube image load backend:v1
minikube image load backend:v2

# Verify images are available in minikube
minikube image ls | grep backend

# You should see:
# docker.io/library/backend:v1
# docker.io/library/backend:v2
```

### 3. Deploy to Kubernetes

```bash
# Apply Kubernetes manifests
minikube kubectl -- apply -f k8s/service.yaml
minikube kubectl -- apply -f k8s/blue-deployment.yaml
minikube kubectl -- apply -f k8s/green-deployment.yaml
minikube kubectl -- apply -f k8s/hpa.yaml

# Wait for deployments to be ready
minikube kubectl -- rollout status deployment/backend-blue
minikube kubectl -- rollout status deployment/backend-green
```

### 4. Make Deploy Script Executable

```bash
# Make the deployment script executable
chmod +x deploy.sh
```

---

## Verify Installation

### 1. Check Pod Status

```bash
# View all pods
minikube kubectl -- get pods -l app=backend

# You should see pods for both blue and green deployments
# Example output:
# NAME                            READY   STATUS    RESTARTS   AGE
# backend-blue-xxxxxxxxx-xxxxx    1/1     Running   0          2m
# backend-blue-xxxxxxxxx-xxxxx    1/1     Running   0          2m
# backend-green-xxxxxxxxx-xxxxx   1/1     Running   0          2m
# backend-green-xxxxxxxxx-xxxxx   1/1     Running   0          2m
```

### 2. Check Service

```bash
# Get service details
minikube kubectl -- get service backend-service

# Example output:
# NAME              TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
# backend-service   LoadBalancer   10.96.xxx.xxx    <pending>     80:3xxxx/TCP   3m
```

> [!NOTE]
> **Minikube LoadBalancer**: The EXTERNAL-IP will show `<pending>` because minikube doesn't provide external IPs by default. Use `minikube service` command instead.

### 3. Test the Application

#### Option A: Using Minikube Service (Recommended)

```bash
# Get the service URL
minikube service backend-service --url

# Use the URL to test
SERVICE_URL=$(minikube service backend-service --url)
curl $SERVICE_URL/
# Output: Hello from Backend v1!

curl $SERVICE_URL/version
# Output: {"version":"v1"}

curl $SERVICE_URL/health
# Output: {"status":"ok","version":"v1"}
```

#### Option B: Port Forward

```bash
# Port forward to local machine
minikube kubectl -- port-forward service/backend-service 8080:80

# In another terminal, test:
curl http://localhost:8080/
curl http://localhost:8080/version
curl http://localhost:8080/health
```

#### Option C: Minikube Tunnel (Alternative)

```bash
# In a separate terminal, run minikube tunnel (requires sudo)
minikube tunnel

# This will assign an external IP to the LoadBalancer service
# Now check the service again
minikube kubectl -- get service backend-service

# You should see an EXTERNAL-IP assigned
# Use it to test:
curl http://<EXTERNAL-IP>/
```

### 4. Test Blue-Green Deployment

```bash
# Get the service URL
SERVICE_URL=$(minikube service backend-service --url)

# Switch to green version
./deploy.sh green

# Test again
curl $SERVICE_URL/
# Output: Hello from Backend v2!

# Switch back to blue
./deploy.sh blue

# Test again
curl $SERVICE_URL/
# Output: Hello from Backend v1!
```

### 5. Check Auto-scaling

```bash
# View HPA status
minikube kubectl -- get hpa backend-hpa

# Watch HPA (may take a few minutes for metrics to appear)
minikube kubectl -- get hpa backend-hpa --watch

# Generate load to test scaling (optional)
# In a separate terminal:
for i in {1..1000}; do curl http://localhost:$NODE_PORT/ > /dev/null 2>&1; done
```

---

## Next Steps

### Production Considerations

1. **Set up a container registry**

   - Use Docker Hub, AWS ECR, or Google Container Registry
   - Push images to registry instead of importing locally
2. **Configure persistent storage**

   - Set up persistent volumes for stateful applications
   - Configure backup solutions
3. **Implement monitoring**

   - Install Prometheus and Grafana
   - Set up logging with ELK or Loki
4. **Security hardening**

   - Enable RBAC (Role-Based Access Control)
   - Use network policies
   - Scan images for vulnerabilities
5. **CI/CD Integration**

   - Set up Jenkins, GitLab CI, or GitHub Actions
   - Automate build and deployment process

### Learning Resources

- **Kubernetes Basics**: https://kubernetes.io/docs/tutorials/kubernetes-basics/
- **k3s Documentation**: https://docs.k3s.io/
- **Blue-Green Deployments**: See [DEPLOYMENT.md](DEPLOYMENT.md)
- **Docker Best Practices**: https://docs.docker.com/develop/dev-best-practices/

---

## Troubleshooting

### Docker Issues

```bash
# Docker daemon not starting
sudo systemctl status docker
sudo journalctl -u docker

# Permission denied
groups  # Check if user is in docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Kubernetes Issues

```bash
# Minikube not starting
minikube status
minikube logs

# minikube kubectl -- not working
minikube kubectl -- cluster-info

# Restart minikube
minikube stop
minikube start

# Pods not starting
minikube kubectl -- describe pod <pod-name>
minikube kubectl -- logs <pod-name>
```

### Image Issues

```bash
# Image not found
minikube image ls | grep backend  # List minikube images
docker images                      # List Docker images

# Re-import images
minikube image load backend:v1
minikube image load backend:v2

# Verify
minikube image ls | grep backend
```

### Service Access Issues

```bash
# Get detailed service info
minikube kubectl -- get service backend-service -o yaml

# Check endpoints
minikube kubectl -- get endpoints backend-service

# Check pod IPs
minikube kubectl -- get pods -o wide
```

---

## Summary

You now have a complete Blue-Green deployment environment running on Ubuntu!

**What you've accomplished:**

- Docker installed and configured
- Minikube cluster running
- Node.js development environment
- Application built and containerized
- Blue and Green deployments active
- Zero-downtime deployment capability

**Useful Commands:**

```bash
# View everything
minikube kubectl -- get all

# Watch pods
minikube kubectl -- get pods --watch

# View logs
minikube kubectl -- logs -f -l app=backend

# Switch versions
./deploy.sh blue    # or green

# Scale manually
minikube kubectl -- scale deployment backend-blue --replicas=5
```

For detailed deployment strategies, see [DEPLOYMENT.md](DEPLOYMENT.md).
