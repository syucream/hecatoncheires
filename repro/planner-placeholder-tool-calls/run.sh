#!/bin/bash
# Runs the scenario N times through the eval harness and summarises what the
# planner did. The outcome is probabilistic, so a single run proves little.
#
# Usage:
#   HECATONCHEIRES_LLM_CLAUDE_API_KEY=... ./run.sh <hecatoncheires-binary> [n] [concurrency]
#
# Build the binary from the commit under test (`go build -o /path/bin .`). Only the
# LLM API is contacted: the repository, agent runtime and Slack are in-process
# fakes, and the scenario wires no live tool.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
N="${2:-10}"
CONC="${3:-5}"
OUT="$HERE/out/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT/scenarios"

for i in $(seq -w 1 "$N"); do
  sed "s/^id          = \"planner-nothing-to-do\"/id          = \"planner-nothing-to-do-$i\"/" \
    "$HERE/scenario.toml" > "$OUT/scenarios/scenario_$i.toml"
done

# The harness subcommand is held in a variable only so this script reads the
# same in every shell wrapper; it is the plain `eval` subcommand.
SUB=eval
HECATONCHEIRES_LOG_LEVEL=debug HECATONCHEIRES_LOG_FORMAT=json \
  "$BIN" "$SUB" \
  --global-config="$HERE/global.toml" \
  --llm-model=claude-sonnet-5-5 \
  --concurrency="$CONC" \
  --dump-dir="$OUT/dump" --dump-all \
  "$OUT/scenarios" > "$OUT/run.log" 2>&1 || true

"$HERE/summarize.sh" "$OUT/run.log"
echo "log: $OUT/run.log"
