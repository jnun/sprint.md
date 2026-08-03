#!/usr/bin/env python3
"""
SprintBias — a bug report becomes a real, workable task.

A pretend, cinematic run: a new user files a bug, then watches the report turn
into work the pipeline can run — a task with a real Problem and a testable
success check, dropped where the pipeline expects it. The report is a note; the
task is work. This demo is that conversion. Pure theater: it touches nothing in
your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 bug.py
Flags:  --fast (no delays)   --no-color   -h/--help
"""

import sys
import time
import shutil
import random

# ── flags ────────────────────────────────────────────────────────────────────
FAST = "--fast" in sys.argv
NO_COLOR = "--no-color" in sys.argv or not sys.stdout.isatty()
if "-h" in sys.argv or "--help" in sys.argv:
    print(__doc__)
    sys.exit(0)

# ── ansi palette ──────────────────────────────────────────────────────────────
def _c(code):
    return "" if NO_COLOR else code

RESET  = _c("\033[0m")
BOLD   = _c("\033[1m")
DIM    = _c("\033[2m")
GREEN  = _c("\033[38;5;42m")
CYAN   = _c("\033[38;5;44m")
BLUE   = _c("\033[38;5;39m")
YELLOW = _c("\033[38;5;220m")
ORANGE = _c("\033[38;5;208m")
RED    = _c("\033[38;5;203m")
GREY   = _c("\033[38;5;245m")
PURPLE = _c("\033[38;5;177m")
WHITE  = _c("\033[97m")

WIDTH = min(shutil.get_terminal_size((80, 24)).columns, 78)

# ── timing helpers ────────────────────────────────────────────────────────────
def nap(seconds):
    if not FAST:
        time.sleep(seconds)

def type_out(text, color=WHITE, cps=(0.012, 0.03)):
    """Typewriter effect, char by char, with tiny human jitter."""
    sys.stdout.write(color)
    for ch in text:
        sys.stdout.write(ch)
        sys.stdout.flush()
        if not FAST:
            time.sleep(random.uniform(*cps))
    sys.stdout.write(RESET + "\n")
    sys.stdout.flush()

def line(text="", color="", delay=0.05):
    sys.stdout.write(color + text + RESET + "\n")
    sys.stdout.flush()
    nap(delay)

def prompt_and_type(cmd):
    """Render a shell prompt, pause like a thinking human, then type the cmd."""
    sys.stdout.write(f"{GREEN}➜{RESET}  {CYAN}~/my-app{RESET} {DIM}${RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.4, 0.9))
    type_out(cmd, color=WHITE)
    nap(0.35)

def spinner(label, ticks=8, done="done", tone=GREEN, mark="✓"):
    frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    if FAST:
        line(f"  {GREY}{label}… {tone}{done}{RESET}")
        return
    for i in range(ticks):
        sys.stdout.write(f"\r  {PURPLE}{frames[i % len(frames)]}{RESET} {GREY}{label}…{RESET}")
        sys.stdout.flush()
        time.sleep(0.09)
    sys.stdout.write(f"\r  {tone}{mark}{RESET} {GREY}{label} — {tone}{done}{RESET}        \n")
    sys.stdout.flush()

def rule(char="─"):
    line(f"{GREY}{char * WIDTH}{RESET}")

def act(title, subtitle):
    print()
    line(f"{BOLD}{ORANGE}{title}{RESET}")
    line(f"{DIM}{subtitle}{RESET}", delay=0.2)
    rule()
    nap(0.3)

def beat(text):
    """A narrator aside — the 'why' between commands."""
    nap(0.2)
    line(f"  {DIM}{PURPLE}❯ {text}{RESET}", delay=0.3)
    nap(0.3)

# ── output atoms (fake SprintBias responses) ───────────────────────────────────
def ok(text):    line(f"  {GREEN}✓{RESET} {text}")
def held(text):  line(f"  {ORANGE}⏸{RESET} {text}")
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

def claude(text):
    """A streamed line from the assistant in a chat session."""
    sys.stdout.write(f"  {PURPLE}claude{RESET} {DIM}│{RESET} ")
    sys.stdout.flush()
    type_out(text, color=WHITE, cps=(0.006, 0.016))
    nap(0.2)

def you(text):
    """The user's reply in a chat session."""
    sys.stdout.write(f"  {GREEN}you{RESET}    {DIM}│{RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.5, 1.0))
    type_out(text, color=CYAN, cps=(0.01, 0.028))
    nap(0.2)

# ── a faux file card, so you SEE the report vs the task ───────────────────────
def card(path, path_color, rows):
    """Render a small file preview: a header path and dim key/value rows."""
    line(f"    {DIM}┌─{RESET} {path_color}{path}{RESET}")
    for k, v in rows:
        line(f"    {DIM}│{RESET}  {GREY}{k}{RESET} {DIM}{v}{RESET}")
    line(f"    {DIM}└─{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}a report becomes work{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — a bug report turns into a real, workable task{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    # Same trust promise as S0/S1 — the sandbox is the first thing you feel.
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  file the bug",
        "you hit something broken. capture it before it slips — it's a note, not work yet.")

    beat("A user just told you exports are losing data. Get it out of your head "
         "and into the inbox.")
    prompt_and_type('./sprint.sh newbug "CSV export drops the last row"')
    ok(f"Created bug: {BLUE}docs/bugs/8-csv-export-drops-the-last-row.md{RESET}")
    nap(0.4)
    card("docs/bugs/8-csv-export-drops-the-last-row.md", ORANGE, [
        ("Severity", "HIGH"),
        ("Problem ", "the last row is missing from the exported file"),
        ("Steps   ", "1. export any table  2. open the CSV  3. last row gone"),
    ])
    nap(0.4)
    beat("This is a report, not a task. docs/bugs/ is a flat inbox — no lifecycle "
         "folders, no gate, nothing a headless run can pick up. It's a sticky note "
         "that won't get lost.")
    nap(0.7)

def act2():
    act("ACT 2  ·  convert it to work",
        "the whole point — a report becomes a task the pipeline can run.")

    beat("Sweep the bug inbox. For each report you decide: turn it into a fix "
         "task, or close it. This one's real — work it.")
    prompt_and_type("./sprint.sh chat bugs")
    note("1 open report in docs/bugs/ — reviewing")
    print()
    claude("Bug 8: \"CSV export drops the last row.\" To make this a task a run "
           "can finish, I need the shape of the fix. When does it drop — always, "
           "or only sometimes?")
    you("only when the file has no trailing newline. the writer skips the final "
        "buffer. it should always flush the last row.")
    claude("That's a testable fix. Minting a task: Problem as who-can't-do-what, "
           "and a Success check a run can prove.")
    print()
    nap(0.4)
    # This is the beating heart: report -> task file with real Problem + success.
    spinner("converting report 8 → fix task", ticks=12, done="task minted")
    card("docs/tasks/backlog/43-fix-csv-export-drops-the-last-row.md", GREEN, [
        ("Problem ", "a user exports a table and the CSV is missing the final row"),
        ("Success ", "☐ export a table with no trailing newline → every row present"),
        ("         ", "☐ round-trip the CSV → row count matches the source"),
    ])
    ok(f"Minted {BLUE}docs/tasks/backlog/43-fix-csv-export-drops-the-last-row.md{RESET}")
    line(f"    {GREY}docs/bugs/8{RESET} {DIM}→{RESET} {DIM}deleted — its job is done, the task carries it now.{RESET}")
    nap(0.5)
    beat("The report's fuzzy \"last row is missing\" became a Problem with a "
         "person in it and a Success check a run can verify. THAT is the "
         "conversion — a note turned into workable work.")
    nap(0.7)

def act3():
    act("ACT 3  ·  put it in line",
        "it's a normal task now — it enters the sprint the same way everything does.")

    beat("43 sits in backlog/ — captured, not yet queued. Talk it into the "
         "sprint; the gate screens it on the way in.")
    prompt_and_type("./sprint.sh chat 43")
    print()
    spinner("gate: judging workability", done="READY")
    moved("backlog/43", "next/43   · READY ✓")
    ok(f"Task 43 is queued. {GREY}next/ IS the sprint — `work` will run it.{RESET}")
    nextstep("./sprint.sh work   → drains READY tasks to review/")
    nap(0.5)
    beat("From here it's indistinguishable from a task you typed by hand. The bug "
         "didn't get special-cased — it got converted, then it flows.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — a report became work.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}a report is a note{RESET}      "
         f"{GREY}docs/bugs/ is a flat inbox — nothing runs it{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}conversion makes it work{RESET} "
         f"{GREY}a real Problem + a success a run can prove{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}then it just flows{RESET}      "
         f"{GREY}backlog → next → the pipeline, like any task{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}newbug → chat bugs (convert) → chat 43 (queue){RESET}")
    print()
    line(f"  {DIM}see it end to end:{RESET} {CYAN}./sprint.sh learn session{RESET}")
    print()
    rule("═")
    print()

def main():
    try:
        banner()
        act1()
        act2()
        act3()
        outro()
    except KeyboardInterrupt:
        sys.stdout.write(RESET + "\n" + DIM + "  …demo interrupted.\n" + RESET)
        sys.exit(130)

if __name__ == "__main__":
    main()
