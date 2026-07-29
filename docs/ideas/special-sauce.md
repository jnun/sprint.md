# Idea: Special Sauce

**Status:** DRAFT
**Created:** 2026-01-25

---

## Instructions

This document helps refine a rough idea into a clear definition.

**For humans:** Work through each section below. Answer the questions honestly. If something is unclear, leave it and come back.

**For AI agents:** Read `docs/sprintmd/ai/feynman-method.md` for the full protocol. Guide the user through each phase with questions. Do not fill sections without user input.

---

## Phase 1: The Problem

*What problem does this solve? Who has this problem? What happens if we don't solve it?*

**The problem:** New product builders get lost in abstraction or complexity. They either stay stuck in planning mode (never ship) or jump straight to building (build the wrong thing).

**Who has it:** Anyone starting a new product, or anyone new to structured product development.

**What happens without this:** People define too many features, build without clarity, and can't tell if what they built actually delivers value.

**The fix:** A forcing function that makes them (1) commit to a single value proposition and (2) define the smallest possible feature that proves or disproves it.

---

## Phase 2: Plain English

*Describe this idea so anyone on the team can understand it. No jargon. No technical terms.*

**Feature name:** "What's the Special Sauce"

New product builders get stuck. They either plan forever or build blindly. This feature gives them one question to answer: "What's the one thing your product does better than anything else, and how do you prove it?"

That question forces a choice—pick one thing, then build the smallest test of whether anyone actually wants it.

**Jargon check:**
- "value proposition" → "the one thing your product does better than anything else"
- "forcing function" → "a question that won't let you dodge the hard choice"

---

## Phase 3: What It Does

*List the specific things this idea enables. Each should be concrete and testable.*

**The direct path:**
- [ ] Ask: "What's the one thing your product does better than anything else?"
- [ ] Force them to write it in one sentence (no essays, no feature lists)

**The scaffolded path (if stuck):**
- [ ] Ask: "What's your why?" → capture motivation
- [ ] Ask: "What's the problem we're solving?" → define the problem
- [ ] Ask: "What's the simplest way to get traction on that problem?" → find the action
- [ ] Synthesize → arrive at the special sauce

**Then, for both paths:**
- [ ] Ask: "How would you prove this to a stranger in 5 minutes?"
- [ ] Turn that proof into a testable feature definition
- [ ] Output: a feature doc ready for task breakdown

---

## Phase 4: Open Questions

*What's still unclear? What needs research? What are we assuming?*

**All resolved:**
- Command: `./sprint.sh sauce` (new functionality)
- Human + AI powered: AI instructions go in `docs/sprintmd/ai/`, theory in `docs/sprintmd/theory/`
- Fallback scaffolding: If user can't articulate sauce directly, walk them through:
  1. "What's your why?" (motivation)
  2. "What's the problem we're solving?" (problem)
  3. "What's the simplest way to get traction on that problem?" (action)
  4. → Leads to: the special sauce (one unique thing, simply explained)

**Core insight:** You can build 100 features in a big project, but sauce gets you ONE testable feature deployed quickly. It's the singular hack, the big shortcut.

---

## Ready to Graduate?

When all sections are filled and open questions are resolved, create a feature with `./sprint.sh newfeature special-sauce` and tasks with `./sprint.sh newtask`.

---

## Raw Notes

*Dump any thinking, conversation logs, or rough notes here.*

