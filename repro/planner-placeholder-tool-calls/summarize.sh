#!/bin/bash
# Summarises a debug JSON log written by run.sh.
#   - posts:          slack__post_to_case_channel calls, by the agent that made
#                     them ("job" = the planner itself, "task" = a sub-agent)
#   - runs that post: distinct runs with at least one such call
#   - rejections:     planner outputs the parser refused, by reason
#   - planner tool errors: e.g. calls to tools that do not exist (notion__none)
# Requires jq.
set -euo pipefail
LOG="$1"
events() { grep '"appended job run event"' "$LOG" || true; }

echo "== posts by agent"
events | jq -r 'select(.kind=="TOOL_CALL" and .tool_name=="slack__post_to_case_channel") | .agent' | sort | uniq -c
echo "== runs that posted"
events | jq -r 'select(.kind=="TOOL_CALL" and .tool_name=="slack__post_to_case_channel") | .root_id' | sort -u | wc -l
echo "== planner output rejections"
{ grep -o '"error":"planexec: [a-z]* output rejected[^"]\{0,100\}' "$LOG" || true; } | sort | uniq -c | sort -rn
echo "== planner tool call errors"
{ grep '"msg":"planexec: planner tool call"' "$LOG" || true; } | jq -r '.error[0:100]' | sort | uniq -c
echo "== suite summary"
{ grep -A12 "suite summary" "$LOG" || true; }
