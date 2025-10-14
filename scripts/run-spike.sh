#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

# Defaults (override with env vars)
: "${THREADS:=50}"
: "${RAMPUP:=60}"
: "${DURATION:=300}"
: "${TARGET_HOST:=httpbin}"
: "${TARGET_PORT:=80}"

mkdir -p jmeter/results

SCENARIO="spike"
mkdir -p "jmeter/results/spike"

docker run --rm   --network httpbin-perf_perfnet   -v "$PWD/jmeter":/jmeter   -w /jmeter   jmeter:5.6.3   -q config/user.properties   -n -t testplans/httpbin_spike.jmx   -Jthreads="${THREADS}" -Jrampup="${RAMPUP}" -Jduration="${DURATION}"   -Jtarget_host="${TARGET_HOST}" -Jtarget_port="${TARGET_PORT}"   -Jscenario_name="${SCENARIO}"   -l results/${SCENARIO}.jtl

# HTML report
docker run --rm   -v "$PWD/jmeter":/jmeter   -w /jmeter   jmeter:5.6.3   -g results/${SCENARIO}.jtl -o results/spike/html

echo "Report ready: jmeter/results/spike/html/index.html"