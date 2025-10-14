#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-load}" # load|stress|spike|soak
DUR=120
USERS=50
RAMP=30

case "$TYPE" in
  load)   DUR=120; USERS=50;  RAMP=30 ;;
  stress) DUR=180; USERS=200; RAMP=60 ;;
  spike)  DUR=90;  USERS=200; RAMP=5  ;;
  soak)   DUR=3600;USERS=50;  RAMP=60 ;;
  *) echo "Unknown type $TYPE"; exit 1;;
esac

mkdir -p reports/"$TYPE"

echo ">> Starting dependencies (httpbin, grafana, prometheus, loki, etc.)"
docker compose up -d httpbin grafana prometheus loki promtail

echo ">> Running JMeter in Docker (type=$TYPE users=$USERS dur=$DUR ramp=$RAMP)"
docker run --rm -v "$(pwd)/jmeter":/test -w /test --network host justb4/jmeter:5.6.3   -n -t HttpBin_Perf.jmx   -Jusers="$USERS" -Jduration="$DUR" -JrampUp="$RAMP"   -l results_"$TYPE".jtl

echo ">> Generating HTML report"
docker run --rm -v "$(pwd)/jmeter":/test -w /test --network host justb4/jmeter:5.6.3   -g results_"$TYPE".jtl -o ../reports/"$TYPE"

echo "Done. Open reports/$TYPE/index.html"
