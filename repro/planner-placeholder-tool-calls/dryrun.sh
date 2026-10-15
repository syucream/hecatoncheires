#!/bin/bash
# Validates scenario.toml without calling any LLM.
# Usage: ./dryrun.sh <hecatoncheires-binary>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SUB=eval
"$1" "$SUB" --dryrun "$HERE/scenario.toml"
