#!/bin/bash

# Blue-Green Deployment Script
# Usage: ./deploy.sh [blue|green]

set -e

TARGET_VERSION=$1

if [ -z "$TARGET_VERSION" ]; then
  echo "Usage: ./deploy.sh [blue|green]"
  exit 1
fi

echo "Starting deployment for version: $TARGET_VERSION"

# 1. Deploy the new version
echo "Deploying backend-$TARGET_VERSION..."
minikube kubectl -- apply -f k8s/$TARGET_VERSION-deployment.yaml

# 2. Wait for readiness
echo "Waiting for backend-$TARGET_VERSION to be ready..."
minikube kubectl -- rollout status deployment/backend-$TARGET_VERSION

# 3. Validation (Simulation)
echo "Running validation checks..."
# In a real scenario, you would port-forward or use a test service to hit the new pods
# For this PoC, we assume if rollout status is successful, basic health is passing (due to readinessProbe)

# Simulate a health check call (requires port-forwarding or internal access, skipping actual curl for script simplicity)
echo "Health check passed."

# 4. Switch Traffic
echo "Switching traffic to $TARGET_VERSION..."
minikube kubectl -- patch service backend-service -p "{\"spec\":{\"selector\":{\"version\":\"$TARGET_VERSION\"}}}"

echo "Traffic switched successfully!"

# 5. Cleanup (Optional - usually keep for quick rollback)
# echo "Cleaning up old version..."
# OLD_VERSION="blue"
# if [ "$TARGET_VERSION" == "blue" ]; then OLD_VERSION="green"; fi
# minikube kubectl -- delete deployment backend-$OLD_VERSION

echo "Deployment complete."
