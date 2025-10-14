# httpbin-perf

End-to-end performance engineering showcase around the **HTTPBin** API running locally with Docker (and optionally Kubernetes with Helm).

**Highlights**
- Docker Compose stack: httpbin, Grafana, Prometheus (OS metrics), Loki + Promtail (logs), Jaeger (traces; optional), Kafka (optional).
- JMeter framework with parameterization, assertions, and 4 workload types (Load, Stress, Spike, Soak).
- GitHub Actions CI: smoke perf test on each push; HTML report uploaded as artifact and optionally published via GitHub Pages.
- Helm chart to deploy on Kubernetes (httpbin + service + optional ingress).
- Docs site under `docs/` suitable for GitHub Pages (project overview and links to artifacts).

---

## Quick Start (No installs)

1. **Download ZIP** from your ChatGPT session and unzip locally.
2. **Create GitHub repo** `amans900/httpbin-perf` and upload the entire folder (use GitHub web UI if you don't have Git installed).
3. **Enable GitHub Pages**: Settings → Pages → Build from `docs/` root → Save.
4. **Run local stack with Docker Desktop** (install if needed):  
   ```bash
   cd httpbin-perf
   docker compose up -d
   ```
   - httpbin: http://localhost:8090
   - Grafana: http://localhost:3000 (admin/admin)
   - Prometheus: http://localhost:9090
   - Jaeger: http://localhost:16686 (optional)
   - Loki: http://localhost:3100
5. **Run JMeter tests (headless)**:  
   ```bash
   ./scripts/run_local.sh load
   # or: ./scripts/run_local.sh stress | spike | soak
   ```
   Reports will appear under `reports/<testtype>/index.html`.

## CI: GitHub Actions
Each push runs a **smoke** JMeter test against the httpbin service (spun up via Docker in the workflow). The HTML report is uploaded as an artifact. See `.github/workflows/perf-smoke.yml`.

## Kubernetes (Optional)
Assuming a K8s cluster and Helm installed:
```bash
helm upgrade --install httpbin-perf k8s/helm/httpbin-perf -n perf --create-namespace
```
If you have an ingress controller, set the host via values:  
```bash
helm upgrade --install httpbin-perf k8s/helm/httpbin-perf -n perf --set ingress.enabled=true --set ingress.host=httpbin.local
```

## Test Strategy
- **Critical endpoints**: `/get`, `/post`, `/delay/{n}`, `/status/{code}`.
- **Metrics**: p50/p90/p95, error %, RPS/throughput, CPU/mem, container restarts, GC (if applicable).
- **Assertions**: avg < 2s, error rate < 1%.
- **Workloads**:
  - Load: steady concurrency at expected traffic.
  - Stress: ramp until break point.
  - Spike: sudden surge; observe recovery.
  - Soak: hours-long stability test.

## Tools
- Performance: **JMeter** (headless) in Docker.
- Metrics: **Prometheus** node/host metrics (for demo).
- Observability: **Grafana** (dashboards), **Loki+Promtail** (logs).
- Tracing: **Jaeger** (optional; httpbin is not instrumented but stack included to show capability).
- Messaging (optional): **Kafka** to demonstrate integration readiness.

---

## Repo Layout
```
.
├── docs/                      # GitHub Pages site
├── jmeter/                    # Test plans, data, properties
├── scripts/                   # Local helper scripts
├── grafana/dashboards/        # JSON dashboards
├── prometheus/                # Prometheus config
├── loki/                      # Loki config
├── promtail/                  # Promtail config
├── k8s/helm/httpbin-perf/     # Helm chart
├── docker-compose.yml
├── Jenkinsfile                # Optional (Jenkins pipeline)
└── README.md
```

## Credentials
Grafana: `admin/admin` (change in `docker-compose.yml`).

## Notes
- For interview/demo: run `docker compose up -d`, open Grafana, run `./scripts/run_local.sh load`, show reports + Grafana.
- For CI smoke thresholds: keep conservative to avoid flakes on shared runners.
