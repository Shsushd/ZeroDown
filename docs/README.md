# Documentation Index

Complete documentation for the Blue-Green Deployment PoC project.

## Documentation Overview

This project includes comprehensive documentation to help you set up, deploy, and manage the Blue-Green deployment system from scratch.

## Main Documentation

### [README.md](../README.md)

**Start here!** Project overview, quick start guide, and introduction to Blue-Green deployments.

**Contains:**

- Project overview and features
- Architecture diagram
- Quick start guide
- API endpoints documentation
- Basic troubleshooting

**Best for:** Understanding what the project does and getting a quick overview.

---

### [SETUP.md](../SETUP.md)

**Complete setup guide from vanilla Ubuntu server.** Step-by-step instructions for installing all prerequisites.

**Contains:**

- System requirements
- Docker installation
- Minikube installation
- Node.js setup
- Project build and deployment
- Verification steps

**Best for:** First-time setup on a fresh Ubuntu server.

**Time estimate:** 30-60 minutes for complete setup.

---

### [DEPLOYMENT.md](../DEPLOYMENT.md)

**Detailed deployment strategies and procedures.** Deep dive into Blue-Green deployment patterns.

**Contains:**

- Deployment strategies explained
- Step-by-step deployment process
- Rollback procedures
- Advanced patterns (Canary, A/B testing)
- Production best practices
- Monitoring and observability

**Best for:** Understanding deployment workflows and production practices.

---

## Reference Documentation

### [docs/QUICK_REFERENCE.md](QUICK_REFERENCE.md)

**Essential commands at your fingertips.** Quick reference for daily operations.

**Contains:**

- Quick start commands
- Common workflows
- Kubectl commands
- Docker commands
- Troubleshooting commands

**Best for:** Day-to-day operations and quick lookups.

**Print this for easy access during deployments!**

---

### [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**Solutions to common issues.** Comprehensive troubleshooting guide.

**Contains:**

- Docker issues
- Kubernetes issues
- Pod problems
- Service/networking issues
- Deployment issues
- HPA/scaling issues
- Performance problems

**Best for:** Debugging when things go wrong.

---

## Documentation by Use Case

### I want to...

#### Set up the project for the first time

1. Read [README.md](../README.md) - Understand the project
2. Follow [SETUP.md](../SETUP.md) - Complete installation
3. Verify with commands from [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

#### Learn how to deploy

1. Read [DEPLOYMENT.md](../DEPLOYMENT.md) - Understand deployment strategies
2. Practice with commands from [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
3. Reference [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if issues occur

#### Fix a problem

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Find your issue
2. Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Get diagnostic commands
3. Refer to [README.md](../README.md) - Review architecture if needed

#### Perform daily operations

- Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) as your primary resource

---

## Documentation Status

| Document           | Status   | Last Updated |
| ------------------ | -------- | ------------ |
| README.md          | Complete | 2025-11-21   |
| SETUP.md           | Complete | 2025-11-21   |
| DEPLOYMENT.md      | Complete | 2025-11-21   |
| QUICK_REFERENCE.md | Complete | 2025-11-21   |
| TROUBLESHOOTING.md | Complete | 2025-11-21   |

---

## Learning Path

### Beginner Path

1. **Start:** [README.md](../README.md) - Overview
2. **Setup:** [SETUP.md](../SETUP.md) - Installation
3. **Practice:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Basic commands
4. **Deploy:** [DEPLOYMENT.md](../DEPLOYMENT.md) - Simple deployment

### Intermediate Path

1. **Review:** [DEPLOYMENT.md](../DEPLOYMENT.md) - Advanced patterns
2. **Master:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - All workflows
3. **Debug:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

### Advanced Path

1. **Production:** [DEPLOYMENT.md](../DEPLOYMENT.md) - Best practices
2. **Optimize:** Performance tuning sections
3. **Custom:** Extend the system for your needs

---

## Quick Search

### Installation & Setup

- **Ubuntu setup** → [SETUP.md](../SETUP.md)
- **Docker installation** → [SETUP.md#install-docker](../SETUP.md#install-docker)
- **Minikube setup** → [SETUP.md#install-minikube](../SETUP.md#install-minikube)
- **Node.js installation** → [SETUP.md#install-nodejs](../SETUP.md#install-nodejs)

### Deployment

- **Deploy new version** → [DEPLOYMENT.md#blue-green-deployment-process](../DEPLOYMENT.md#blue-green-deployment-process)
- **Switch traffic** → [DEPLOYMENT.md#step-4-switch-traffic](../DEPLOYMENT.md#step-4-switch-traffic)
- **Rollback** → [DEPLOYMENT.md#rollback-procedures](../DEPLOYMENT.md#rollback-procedures)

### Operations

- **Essential commands** → [QUICK_REFERENCE.md#essential-commands](QUICK_REFERENCE.md#essential-commands)
- **Monitoring** → [DEPLOYMENT.md#monitoring-and-observability](../DEPLOYMENT.md#monitoring-and-observability)
- **Scaling** → [QUICK_REFERENCE.md#scaling](QUICK_REFERENCE.md#scaling)

### Troubleshooting

- **Pod issues** → [TROUBLESHOOTING.md#pod-issues](TROUBLESHOOTING.md#pod-issues)
- **Service issues** → [TROUBLESHOOTING.md#servicenetworking-issues](TROUBLESHOOTING.md#servicenetworking-issues)
- **Performance** → [TROUBLESHOOTING.md#performance-issues](TROUBLESHOOTING.md#performance-issues)

---

## Support

If you can't find what you're looking for:

1. Check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide
2. Review relevant sections in other documents
3. Search the codebase for specific configuration
4. Open an issue in the repository

---

## Contributing to Documentation

Found an error or want to improve the docs?

1. Fork the repository
2. Make your changes
3. Test the instructions
4. Submit a pull request

Documentation improvements are always welcome!

---

**Happy learning and deploying!**

---

## Document Tree

```
kurbentes/
├── README.md                  # Project overview and quick start
├── SETUP.md                  # Complete Ubuntu installation guide
├── DEPLOYMENT.md             # Deployment strategies and procedures
├── docs/
│   ├── README.md            # This file - Documentation index
│   ├── QUICK_REFERENCE.md   # Essential commands reference
│   └── TROUBLESHOOTING.md   # Common issues and solutions
├── src/
│   └── server.ts            # Application code
├── k8s/
│   ├── service.yaml         # Service configuration
│   ├── blue-deployment.yaml # Blue deployment
│   ├── green-deployment.yaml # Green deployment
│   └── hpa.yaml             # Auto-scaler
├── Dockerfile               # Container build
├── deploy.sh                # Deployment script
├── package.json
└── tsconfig.json
```
