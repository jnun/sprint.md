# AI provider capability matrix

sprint.md speaks one provider-neutral interface (`fiveday_run` / the `cli/*.sh`
profiles) but providers are not equal. This table is the single source of
truth for what each tier can do, so scripts can exploit Claude Code's
strengths and degrade honestly everywhere else instead of coding to a
lowest common denominator.

Priority order — the tiers we invest in, most-used first: **Claude Code**,
**Cursor**, **OpenAI**, then a **generic** catch-all for everything else.

The active tier is chosen at `setup.sh` time and stored as `PROVIDER=` in
`docs/sprintmd/config`. Query it from any script with `fiveday_ai_tier`
(defined in `lib.sh`); it falls back to inferring the tier from the `CLI=`
binary when `PROVIDER=` is unset.

## Matrix

| Capability            | claude-code | cursor    | openai    | generic |
|-----------------------|-------------|-----------|-----------|---------|
| Exec JSON output      | yes         | no¹       | no¹       | no      |
| Subagent / parallel   | yes         | no        | no        | no      |
| Tool restriction      | yes         | no¹       | no¹       | no      |
| Budget caps           | yes         | no        | no        | no      |
| Model selection       | yes         | no¹       | no¹       | no      |
| Emit-mode detection   | yes         | yes       | no²       | no²     |
| CLI binary            | `claude`    | `cursor-agent` | `codex` | (any) |
| Profile               | `cli/claude.sh` | `cli/default.sh`³ | `cli/default.sh`³ | `cli/default.sh` |

¹ Not wired up. These CLIs may support some of these flags, but no verified
profile maps them yet, so the generic `default.sh` passthrough is used and
the flags are dropped (with a one-line warning naming what was dropped).
Add a `cli/<binary>.sh` profile once the flags are verified against a real
install — see the history note below.

² Emit-mode auto-detection keys on agent-session env vars in
`lib.sh:fiveday_ai_mode` (`CLAUDECODE`, `CURSOR_TRACE_ID`, …). Claude Code
and Cursor set these; the OpenAI/generic CLIs are detected only via the
generic `AI_AGENT` / `FIVEDAY_IN_AGENT` fallbacks or an explicit `MODE=emit`.

³ No dedicated profile ships today. `openai.sh`, `gemini.sh`, and
`mistral.sh` stubs were created by task 178 and deliberately removed in
commit db90170 because they were best-effort and unverified — don't
resurrect them without verifying flags against a real install.

## What "tier" means for a script

```bash
case "$(fiveday_ai_tier)" in
    claude-code)
        # Full orchestration: subagents, --tools restriction, --budget caps,
        # buffered/streamed JSON output for machine-readable audit logs.
        ;;
    cursor|openai|generic)
        # Single-shot prompts only. Ask for structured text in the prompt
        # instead of relying on JSON output; skip parallel/subagent dispatch.
        ;;
esac
```

`claude-code` is the only tier that supports the full flag surface in
`cli/claude.sh` (model, tools, budget, turns, permissions, JSON output,
subagent dispatch). Every other tier routes through `cli/default.sh`, which
runs the bare prompt and drops richer flags with a one-line warning. Provider-
agnostic is a virtue only when it costs nothing; when a Claude-Code-only path
outperforms the generic one, gating it on this tier is acceptable.
