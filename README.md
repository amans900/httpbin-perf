# httpbin-perf

End-to-end performance-testing demo around **HTTPBin** with **Docker**, **JMeter 5.6.3**, **Grafana** (metrics + logs via **InfluxDB** + **Loki**), **Prometheus** + **cAdvisor** (container/node metrics), optional **Kafka**, **Jenkins** CI, and a **Helm** chart for Kubernetes.

> Works on Windows (Docker Desktop), macOS, and Linux. You don't need anything preinstalled except Docker Desktop and Git (Jenkins runs in Docker).

---

## 0) One-time: create GitHub repo

1. Sign up / sign in: https://github.com (username: `amans900`).
2. Create repository: **httpbin-perf** (Public). No template.
3. Locally (PowerShell):
   ```powershell
   git clone https://github.com/amans900/httpbin-perf.git
   cd httpbin-perf
   # copy all files from this zip into this folder, then:
   git add .
   git commit -m "Initial: httpbin-perf stack with JMeter, Grafana, Jenkins, Helm"
   git push origin main
   ```

## 1) Install prerequisites (Windows)

- **Docker Desktop** (with WSL2): https://docs.docker.com/desktop/install/windows-install/
- **Git for Windows**: https://git-scm.com/download/win

> No need to install JMeter or Jenkins manually. Both run in containers.

## 2) Bring up the stack

From the repository root:

```bash
docker compose up -d
```

Services:
- httpbin → http://localhost:8080
- Grafana → http://localhost:3000  (user: admin / pass: admin)
- InfluxDB (JMeter metrics) → http://localhost:8086
- Loki (logs) → http://localhost:3100
- Prometheus → http://localhost:9090
- cAdvisor → http://localhost:8082
- Jenkins → http://localhost:8081  (initial admin password printed in container logs)

> Optional Kafka: `docker compose --profile kafka up -d`

## 3) Run JMeter tests via Docker

Examples:

```bash
# Load test (sustained throughput)
./scripts/run-load.sh

# Stress test (increase until failures)
./scripts/run-stress.sh

# Spike test (sudden surge/burst)
./scripts/run-spike.sh

# Soak test (long duration; adjust DURATION)
./scripts/run-soak.sh
```

Parameters accepted by all scripts (override defaults):
- `THREADS`, `RAMPUP`, `DURATION`, `TARGET_HOST`, `TARGET_PORT`
- Example: `THREADS=200 RAMPUP=60 DURATION=300 ./scripts/run-load.sh`

Artifacts:
- Raw JTL and HTML reports in `jmeter/results/<scenario>/`
- Live metrics in Grafana → Dashboard: **JMeter Overview**

## 4) Explore metrics & logs

- Grafana (http://localhost:3000)
  - **Datasources** pre-provisioned: InfluxDB (JMeter), Prometheus (cAdvisor), Loki (container logs)
  - Dashboards (auto-provisioned):
    - **JMeter Overview** (latency p50/p90/p95, RPS, errors)
    - **Container Metrics** (CPU/Memory/Net via cAdvisor)
    - **Logs Explore** (Loki)

## 5) CI with Jenkins

Jenkins runs at http://localhost:8081 (user setup on first visit).
- Pipeline uses `Jenkinsfile` in this repo:
  - Spin up infra (InfluxDB, Grafana, Loki, Prometheus, cAdvisor, httpbin)
  - Run a **smoke** JMeter test on each push
  - Archive HTML report in Jenkins

### Quick start
```bash
# First run prints initial admin password
docker logs -f httpbin-perf-jenkins-1
# Open Jenkins in browser, complete setup.
# Create a "Pipeline" job pointing to your GitHub repo and Jenkinsfile.
```

## 6) Kubernetes + Helm (optional)

- Install **kind** or **minikube** locally.
- Deploy the chart:
  ```bash
  cd k8s/helm/httpbin-perf
  helm dependency update || true
  helm install httpbin-perf .
  kubectl port-forward svc/httpbin 8080:80
  ```
- Run one-shot JMeter job in the cluster:
  ```bash
  kubectl apply -f k8s/manifests/jmeter-job.yaml
  kubectl logs -f job/jmeter-run
  ```

## 7) Test design (per assignment)

- **Critical endpoints**: `/get`, `/post`, `/delay/{n}`, `/status/{code}`
- **Scenarios**:
  - **Load**: steady concurrency at expected traffic
  - **Stress**: step-up concurrency until SLA violations
  - **Spike**: sudden large burst, observe recovery
  - **Soak**: hours-long run to surface leaks and stability
- **Metrics captured**:
  - Response time (min/avg/max/p90/p95), Throughput (RPS), Error %, Server CPU/Mem/Net (cAdvisor), and container logs (Loki)
- **SLA assertions** (configurable in JMX):
  - Avg RT < 2s, Error rate < 1%

## 8) Reporting

- JMeter HTML reports per run under `jmeter/results/<scenario>/html`
- Grafana dashboards for time-series and drilldown
- Optionally export PNG snapshots from Grafana for inclusion in reports

## 9) Folder layout

```
.
├─ docker-compose.yml
├─ README.md
├─ jenkins/
│  ├─ Jenkinsfile
│  └─ docker/Dockerfile
├─ jmeter/
│  ├─ docker/Dockerfile
│  ├─ testplans/
│  │  ├─ httpbin_base.jmx
│  │  ├─ httpbin_load.jmx
│  │  ├─ httpbin_stress.jmx
│  │  ├─ httpbin_spike.jmx
│  │  └─ httpbin_soak.jmx
│  ├─ data/payloads.json
│  ├─ config/user.properties
│  └─ results/ (generated)
├─ scripts/
│  ├─ run-load.sh
│  ├─ run-stress.sh
│  ├─ run-spike.sh
│  ├─ run-soak.sh
│  └─ run-smoke.sh
├─ grafana/
│  ├─ provisioning/datasources/*.yml
│  ├─ provisioning/dashboards/*.yml
│  └─ dashboards/*.json
├─ prometheus/prometheus.yml
├─ loki/config.yml
├─ promtail/config.yml
├─ k8s/
│  ├─ helm/httpbin-perf/...
│  └─ manifests/jmeter-job.yaml
└─ .github/workflows/perf-smoke.yml (optional)
```

## 10) References

- HTTPBin: https://github.com/postmanlabs/httpbin  (Docker image: `kennethreitz/httpbin`)
- JMeter InfluxDB Backend Listener: https://jmeter.apache.org/usermanual/realtime-results.html
- Jenkins Docker: https://hub.docker.com/r/jenkins/jenkins
- cAdvisor + Prometheus: https://prometheus.io/docs/guides/cadvisor/
- Grafana Loki/Promtail (logs): https://grafana.com/docs/loki/latest/setup/install/docker/

---

**Author notes:** built for a performance-engineering portfolio to showcase: Docker, Git, CI/CD (Jenkins), Kubernetes/Helm, Observability (Grafana/Influx/Prometheus/Loki), and practical test design.
