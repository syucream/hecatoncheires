# Reproduction: planner placeholder tool calls

Reference material for the PR that keeps the plan-execute planner's own tools
read-only and lets round 1 `finalize`. It is not meant to be merged.

## Symptom

A scheduled `planexec` Job whose instructions say "if nothing changed since the
last run, do nothing" sometimes posted meaningless messages to the case thread —
`x`, `test`, `noop`, `dummy`, `Placeholder` — often followed by a second post
apologising for the first. Production logs showed:

- the posts were made by the **planner itself** (`agent=job`), not a sub-agent;
- planner outputs were rejected over and over (`tasks count out of range` with
  `got=0`, `replan set no action`, placeholder questions);
- the planner called tools that do not exist (`notion__none`, `notion__noop`) or
  real ones with no / placeholder arguments.

It started when the deployment switched to a model that answers through Claude
structured outputs.

## Mechanism

1. The Job has nothing to do, but round 1 offers no way to say so: the plan
   schema had no `finalize` and `tasks` must be non-empty. Later rounds rejected
   an output that took no action.
2. Each rejection asks the planner to try again. Under structured outputs the
   only way out of the response schema is a tool call, so the planner answers
   with one, carrying placeholder arguments.
3. The planner's own palette included the writers. When the placeholder call
   was `slack__post_to_case_channel`, it was posted. The next turn saw the post
   and apologised for it.

## Files

| File | Purpose |
|---|---|
| `scenario.toml` | Thread-mode workspace + a `progress_sync`-style planexec Job and one case. The eval fake Slack returns an empty thread, so the correct outcome is "no write at all". |
| `global.toml` | `claude-sonnet-5-5`, budget $2 |
| `run.sh` | Runs the scenario N times and summarises (`summarize.sh`) |
| `summarize.sh` | Posts by agent, rejections, planner tool errors, from the debug JSON log |
| `dryrun.sh` | Validates the scenario without calling the LLM |

## Running

```sh
git switch --detach <commit-under-test> && go build -o /tmp/hct .
HECATONCHEIRES_LLM_CLAUDE_API_KEY=... ./run.sh /tmp/hct 10 5
```

Only the LLM API is contacted. The scenario is probabilistic; run at least 10.

## Results (10 runs each)

| | before (`87eae33`) | after (fix branch) |
|---|---|---|
| runs where the planner posted | 1 (`{"text":"test"}`) | 0 |
| planner output rejections | 18 | 0 |
| planner calls to non-existent tools | 1 (`notion__none`) | 0 |

The same comparison against the deployment's own Job prompt (not included here)
gave 6/20 runs posting `noop` / `dummy` plus an apology before, and 0/20 after.
A positive-path scenario (a Job whose deliverable is one post) posted exactly
once in 5/5 runs after the fix, always from a sub-agent (`agent=task`).
