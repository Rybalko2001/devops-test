# NestJS + Redis Kubernetes Deployment with CI/CD

This project demonstrates a **NestJS application** with a `/redis` endpoint that checks connectivity to Redis, deployed in **Kubernetes** with full **CI/CD pipeline** using **GitHub Actions**.

---

## **Table of Contents**

* [Project Structure](#project-structure)
* [Features](#features)
* [Prerequisites](#prerequisites)
* [Setup & Deployment](#setup--deployment)
* [CI/CD Pipeline](#cicd-pipeline)
* [Kubernetes Manifests](#kubernetes-manifests)
* [Monitoring](#monitoring)
* [Security & Best Practices](#security--best-practices)
* [Architecture Diagram](#architecture-diagram)
* [Testing & Verification](#testing--verification)

---

## **Project Structure**

```
DEVOPS-TEST
├── .github
│   └── workflows
│       └── CI-CD.yaml
├── k8s
│   ├── configmap-app.yaml
│   ├── deployment-app.yaml
│   ├── deployment-redis.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── namespace.yaml
│   ├── networkpolicy.yaml
│   ├── secret-redis.yaml
│   ├── service-app.yaml
│   └── service-redis.yaml
├── src
│   ├── redis
│   │   ├── redis.service.spec.ts
│   │   └── redis.service.ts
│   ├── app.controller.spec.ts
│   ├── app.controller.ts
│   ├── app.module.ts
│   ├── app.service.ts
│   └── main.ts
├── test
│   ├── app.e2e-spec.ts
│   └── jest-e2e.json
├── .dockerignore
├── .env
├── .gitignore
├── .prettierrc
├── dockerfile
├── eslint.config.mjs
├── nest-cli.json
├── package-lock.json
├── package.json
├── README.md
├── tsconfig.build.json
└── tsconfig.json

```

---

## **Features**

* `/redis` endpoint returns `{"status": true/false}` depending on Redis connectivity
* Dockerized with **multi-stage optimized Dockerfile**
* Deployed on **Kubernetes** (works with `kind`, `minikube`, or cloud cluster)
* CI/CD pipeline via **GitHub Actions**
* Secrets management for Redis password
* Prometheus/Grafana monitoring integration
* Horizontal Pod Autoscaler (HPA) for scaling NestJS pods
* Security best practices (non-root containers, read-only filesystem, dropped capabilities)

---

## **Prerequisites**

* Docker & Docker Hub account
* Kubernetes cluster (`kind`, `minikube`, or cloud)
* `kubectl` CLI installed
* GitHub repository for CI/CD
* GitHub secrets setup:

  * `DOCKERHUB_USERNAME`
  * `DOCKERHUB_TOKEN`
  * `KUBECONFIG_DATA` (base64-encoded kubeconfig file)

---

## **Setup & Deployment**

1. **Clone the repository**:

```bash
git clone https://github.com/Rybalko2001/devops-test.git
cd devops-test
```

2. **Build and run locally with Docker**:

```bash
docker build -t nest-redis-demo:latest .
docker run -p 3000:3000 --env-file .env nest-redis-demo:latest
```

3. **Deploy to Kubernetes**:

```bash
          kubectl apply -f k8s/namespace.yaml
          kubectl apply -f k8s/secret-redis.yaml
          kubectl apply -f k8s/configmap-app.yaml
          kubectl apply -f k8s/deployment-redis.yaml
          kubectl apply -f k8s/deployment-app.yaml
          kubectl apply -f k8s/service-redis.yaml
          kubectl apply -f k8s/service-app.yaml
          kubectl apply -f k8s/ingress.yaml
          kubectl apply -f k8s/networkpolicy.yaml
          kubectl apply -f k8s/hpa.yaml
          kubectl rollout status deployment/nestjs-app -n app-dev
```

4. **Check the `/redis` endpoint**:

```bash
kubectl port-forward svc/nestjs-service 3000:3000 -n app-dev
curl http://localhost:3000/redis
```

---

## **CI/CD Pipeline**

* Triggered on **push** or **pull request** to `main` or `dev` branches
* Steps in GitHub Actions workflow:

  1. Checkout code
  2. Setup Docker Buildx & QEMU
  3. Login to Docker Hub
  4. Build and push Docker image
  5. Setup `kubectl` with `KUBECONFIG_DATA` secret
  6. Deploy ConfigMaps, Secrets, Redis, and NestJS into Kubernetes
  7. Wait for rollout success

> **Note:** This workflow acts as CI/CD. For GitOps-style deployment, ArgoCD can be integrated.

---

## **Kubernetes Manifests**

* **ConfigMap** → application environment variables
* **Secret** → Redis password
* **Redis Deployment & Service** → standalone Redis pod + ClusterIP service
* **NestJS Deployment & Service** → NestJS pods with HPA
* **SecurityContext** ensures non-root container and read-only filesystem
* **Probes** for liveness and readiness
* **Horizontal Pod Autoscaler (HPA)** to auto-scale NestJS pods based on CPU

---

## **Monitoring**

* **Prometheus Operator** scrapes `/metrics` from NestJS pods
* Grafana dashboards visualize:

  * CPU & Memory usage
  * Redis metrics (`connected_clients`, `commands_total`)
  * Custom HTTP request metrics from NestJS
* Local access via port-forward:

```bash
kubectl port-forward svc/prometheus-operated 9090 -n monitoring
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

---

## **Security & Best Practices**

* Non-root containers (`runAsNonRoot: true`)
* Read-only filesystem (`readOnlyRootFilesystem: true`)
* Dropped Linux capabilities (`capabilities.drop: ["ALL"]`)
* Secrets stored in **Kubernetes Secrets**, never in plain YAML
* Resource requests & limits set for stability

---

## **Architecture Diagram**

```
[GitHub Actions] --> Docker Hub --> Kubernetes Cluster
                                  |-> Redis Pod
                                  |-> NestJS Pods
                                        |-> /redis endpoint
                                        |-> /metrics (Prometheus)
[Prometheus] <--------------------- Scrapes metrics
[Grafana] <------------------------ Visualizes metrics
```

---

## **Testing & Verification**

1. Check pods and services:

```bash
kubectl get pods -n app-dev
kubectl get svc -n app-dev
```

2. Test Redis endpoint:

```bash
curl http://localhost:3000/redis
```

3. Verify HPA:

```bash
kubectl get hpa -n app-dev
```

4. Check Prometheus metrics:

```bash
kubectl port-forward svc/prometheus-operated 9090 -n monitoring
```
