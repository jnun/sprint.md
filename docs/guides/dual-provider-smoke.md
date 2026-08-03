# Dual-provider smoke protocol

A short, repeatable ritual to prove a change works for **both** Claude Code and
Grok Build users before a plan's "ship" task is marked done. It exercises the
real install path — shipped `src/` through `./setup.sh` into a fresh `/tmp`
project — not the dogfood board in this repo, so it catches setup-picker,
empty-project, and provider-config regressions that in-repo dogfood misses.

**Scope.** This is a *maintainer* ritual, run by a human, once, before shipping.
It is not perpetual CI. Budget **~30–60 minutes**. The non-interactive subset is
automated by the opt-in runner `docs/tests/smoke-live-dual-provider.sh` (task
**301**), which mirrors this checklist rather than replacing it:

```bash
LIVE_SMOKE=1 docs/tests/smoke-live-dual-provider.sh   # live steps for both CLIs
```

It launches `claude` and `grok` headlessly to check the exec banner, emit
detection, and one live one-shot per provider, self-skipping (never failing) on
a missing CLI or an auth/network outcome. It is OFF unless `LIVE_SMOKE=1` /
`--live`, so the offline suite stays green. It does **not** cover the fresh
`setup.sh` install legs below — those stay a human step.

**This guide lives in `docs/guides/` (repo-only, not mirrored into `src/`).** It
documents how *we* verify releases; installed projects never receive it.

For the full platform test ladder (unit → emit → this live ritual), start at
**[running-tests.md](./running-tests.md)**.

---

## Preconditions

- `claude` on `PATH` (Claude Code) for the Claude leg; `grok` on `PATH` (Grok
  Build) for the Grok leg. The install/config steps below run without either
  CLI; only the `work`/`chat` execution steps need the matching CLI.
- **Ship before you smoke.** Per the dual-tree rule, `src/` is the distribution
  package and `setup.sh` installs *from it*. Mirror your change first:

  ```bash
  ./ship.sh --dry-run    # preview what mirrors
  ./ship.sh              # mirror docs/sprintmd → src/ and bump VERSION
  ```

  Skipping this smokes the *old* `src/` and the run is meaningless. If you are
  not ready to bump the version, do not smoke yet.

You do **not** need both CLIs configured in the *same* project. Each provider
gets its own fresh tree. (A single dual-configured project is an optional bonus,
not required — see *Bonus* below.)

---

## The protocol

Run from the SprintBias repo root. Each leg is a fresh, throwaway project.

### 1. Claude leg — fresh install → pick Claude → tiny spine

```bash
mkdir -p /tmp/smoke-claude
SPRINT_TARGET=/tmp/smoke-claude ./setup.sh    # at "Choose [Enter=Claude / g=Grok]" press Enter
```

**Pass:** setup ends with `Setup Complete - All Checks Passed!` and

```bash
grep -E '^(CLI|PROVIDER)=' /tmp/smoke-claude/docs/sprintmd/config
# → CLI=claude
# → PROVIDER=claude-code
```

Then run the spine in the fresh tree:

```bash
cd /tmp/smoke-claude
./sprint.sh model show          # header shows CLI: claude / Provider: claude-code;
                                #   roles resolve to Claude models (opus) as "tier default"
./sprint.sh newtask "Smoke: reject empty input on the login form"
./sprint.sh status              # Backlog: 1
```

**Pass:** `model show` reports Claude models for every role, `newtask` creates
`docs/tasks/backlog/1-smoke-reject-empty-input-on-the-login-form.md`, and
`status` counts it.

Now the one real task, executed by the agent (needs `claude` configured). Define
the task file's Problem/Success criteria first (edit the file, or use
`./sprint.sh chat 1`), promote it, and run it:

```bash
./sprint.sh work                # transforms the next READY task via Claude
```

**Pass:** `work` launches Claude (emit mode inside Claude Code; exec launches
`claude` from a plain terminal), produces a diff or a clear "no change needed"
verdict for the task, and the task advances out of `doing/`. A crash, an empty
run with no verdict, or a provider/auth error is a **fail**.

### 2. Grok leg — fresh install → pick Grok → same spine

```bash
mkdir -p /tmp/smoke-grok
SPRINT_TARGET=/tmp/smoke-grok ./setup.sh      # at the door, type: g  then Enter
```

**Pass:**

```bash
grep -E '^(CLI|PROVIDER)=' /tmp/smoke-grok/docs/sprintmd/config
# → CLI=grok
# → PROVIDER=grok-build
```

Same spine, same pass criteria, in `/tmp/smoke-grok` — except `model show` must
report **Grok** models (`grok-4.5`) as the tier default, and `work` launches
`grok`:

```bash
cd /tmp/smoke-grok
./sprint.sh model show          # CLI: grok / Provider: grok-build; roles → grok-4.5
./sprint.sh newtask "Smoke: reject empty input on the login form"
./sprint.sh status
# define the task, then:
./sprint.sh work
```

### 3. Switch / show the model

The model surface has a real backing store (`docs/sprintmd/config` +
`./sprint.sh model`). Prove show/switch in one of the fresh trees:

```bash
./sprint.sh model show          # effective model per role, and where each comes from
./sprint.sh model list          # models the current provider offers
./sprint.sh model set MODEL_DEFAULT grok-4.5     # (grok tree) pin a default…
./sprint.sh model show          # …and confirm the "Default" line and roles reflect it
```

**Pass:** `model set` writes the key into `docs/sprintmd/config` and the next
`model show` reflects it. If `./sprint.sh model` is unavailable in an older
tree, edit `docs/sprintmd/config` directly (`MODEL_DEFAULT=…`) and re-run a
command — same effect, no reinstall.

### 4. Compare

The two legs ran the identical spine on identical inputs. Confirm the only
differences are the provider tier (config), the model names in `model show`, and
which CLI `work` launched — the command surface, folder lifecycle, and task
files are the same on both hosts. A behavioral divergence beyond provider tier
is the bug this protocol exists to surface.

---

## Bonus (optional, not required)

- **Non-interactive install** for the deterministic subset — feed the door on
  stdin so no prompt blocks:

  ```bash
  SPRINT_TARGET=/tmp/smoke-grok ./setup.sh <<'EOF'
  g
  EOF
  ```

- **One dual-configured project** — install once, then flip per run without
  reinstalling, using the per-run provider flags:

  ```bash
  ./sprint.sh -c work     # this run as Claude
  ./sprint.sh -g work     # this run as Grok  (peer flags: --claude / --grok)
  ```

## Clean up

Throwaway trees leave no state worth keeping:

```bash
rm -rf /tmp/smoke-claude /tmp/smoke-grok
```

---

## Last dry run

Recorded from a real run of steps 1–3's install/config/model spine (the
CLI-execution `work` step is the operator's to run with a configured CLI):

| Check | Claude leg | Grok leg |
|-------|-----------|----------|
| `setup.sh` non-interactive install | ✅ `All Checks Passed`, 101 files | ✅ `All Checks Passed` |
| `config` provider tier | ✅ `CLI=claude` / `PROVIDER=claude-code` | ✅ `CLI=grok` / `PROVIDER=grok-build` |
| `model show` provider-correct default | ✅ roles → `opus` (tier default) | ✅ roles → `grok-4.5` (tier default) |
| `newtask` + `status` | ✅ task created, counted in Backlog | ✅ task created, counted |

**Verdict:** install path, provider picker, config write, and model surface pass
on both hosts. The agent-execution (`work`) step is provider-configured and left
to the release operator per this protocol.

---

## Related

| Path | Role |
|------|------|
| `docs/guides/claude-provider-tier.md` | Claude as-built tier |
| `docs/guides/grok-provider-tier.md` | Grok peer tier |
| `docs/tests/smoke-live-dual-provider.sh` | Opt-in runner that automates the non-interactive subset (task 301) |
| `docs/tests/smoke-grok-spine.sh` | Offline exec-shape assertions for the Grok leg (task 296) |
| `setup.sh` / `ship.sh` | Installer + the mirror step this protocol depends on |
| `DOCUMENTATION.md` → dual-tree rule | Why ship-before-smoke |
