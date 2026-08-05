# Idea Refinement Protocol

Guide a user from a raw hunch to a set of features ready to build. Eight phases, divergent first, convergent second. No jargon. No rushing to solutions.

## When to Use

Run this protocol when refining an idea in `docs/ideas/`. Triggered by `./sprint.sh newidea` (AI-assisted) or by an AI agent working with an existing idea file.

## The Two Postures

This protocol has two distinct modes. Get the posture wrong and the whole session fails.

**Phases 1–4 (Divergent): Open up.** Your job is to expand the user's thinking. Suggest angles they haven't considered. Name options they didn't list. Challenge first instincts. Resist convergence — if the user jumps to a solution in Phase 2, pull them back. Ask "what else?" more than "which one?"

**Phases 5–8 (Convergent): Close down.** Your job is to sharpen and pressure-test. Challenge the bet. Name failure modes. Cut scope. If the user wants to keep everything, push for the smallest version. Ask "does this serve the bet?" more than "what else could we add?"

## How to Execute

Work through each phase in order. Ask at least one question per phase before writing content for that phase. Never fill a section without user input. Advance to the next phase when the user's answers satisfy the current phase — don't wait for the user to say "next."

### Phase 1: The Spark

Capture what triggered the idea. The user might arrive with a frustration, a hunch, something they observed, or a vague "what if." All are valid entry points.

Ask:
- What made you think of this? What happened?

Don't interrogate — just capture. This phase is about getting the raw impulse on paper. One or two exchanges is enough.

### Phase 2: The Problem

Turn the spark into a problem statement. This is where divergent thinking starts — push the user to go wider than their first answer.

Ask:
- Who specifically has this problem? Can you name a real person or role?
- How do you know it's real — have you seen it, heard about it, or are you guessing?
- What do they do today to work around it?
- What does it cost them (time, money, frustration)?
- What happens if nobody solves this?

Challenge assumptions: if the user says "everyone has this problem," ask who has it worst. If they describe a solution instead of a problem, redirect: "That's a solution — what's the problem underneath it?"

### Phase 3: The Landscape

Map what already exists. The user may not have looked, so help them think about it.

Ask:
- What already exists that addresses this? (tools, processes, workarounds)
- Has this been tried before — by you or by others? What happened?
- What's adjacent to this that we can learn from?
- What's different about your situation that makes existing solutions insufficient?

Suggest angles the user hasn't mentioned: competitors, open-source tools, manual processes that work surprisingly well, adjacent domains with similar problems.

### Phase 4: The Brainstorm

Generate multiple approaches. The user needs at least three — more is better. Push for range: obvious, lazy, ambitious, weird.

Ask:
- What's the most obvious way to solve this?
- What's the laziest solution that might work? (minimum effort, maximum learning)
- If you had unlimited resources, what would you build?
- What's a completely different angle — something nobody would expect?

If the user stalls at two, offer a third yourself. Name approaches they haven't considered. This phase succeeds when the user has genuine options to choose from, not when they've confirmed what they already wanted to do.

### Phase 5: The Bet

Shift to convergent mode. The user picks a direction and states it as a testable hypothesis.

Ask:
- Looking at these options, which one are you drawn to and why?
- Can you state it as a bet: "We believe [approach] will [solve problem] for [people] because [insight]"?
- What's the core insight — why this approach over the others?

Help refine the bet statement until it's specific. A good bet names the approach, the problem, the audience, and the reasoning. "We believe a simple checklist will reduce onboarding confusion for new hires because they currently have no single source of truth" — that's specific. "We believe this will help people" — that's not.

### Phase 6: The Stress Test

Assume the bet fails. The AI's job here is adversarial — name at least one reason the bet could fail and ask the user to respond.

Ask:
- Imagine it's six months from now and this completely failed. What went wrong?
- What are you assuming that might not be true?
- What does this depend on that has to exist first?

After the user responds, push back: "You said [assumption] — how confident are you? What would change your mind?" The goal is not to kill the idea but to find its weak points while the cost of pivoting is low.

### Phase 7: The Scope

Cut to the smallest thing that tests the bet. The user will want to include too much — push for less.

Ask:
- What's the absolute minimum that would test whether this bet is right?
- What can you cut that feels important but isn't needed to learn?
- Where's the line between v1 and later?

If the user's v1 takes more than a week (or whatever "small" means in their context), it's too big. Help them find the embarrassingly small version.

### Phase 8: The Handoff

Convert the idea into features. Each feature should trace back to the bet.

Ask:
- What features does this idea produce?
- For each feature, how does it test or serve the bet?
- Is there anything in the feature list that doesn't connect to the bet?

Remove features that don't serve the bet — they belong in "later," not v1.

## After the Session

Evaluate the graduation checklist. The gates are:

| Gate | Phase | What to check |
|------|-------|--------------|
| Problem validated | 2 | Names real people with a real cost, not hypothetical |
| Landscape checked | 3 | Shows awareness of what exists and why this is different |
| Bet articulated | 5 | Clear hypothesis with approach, audience, and "because" |
| Stress test completed | 6 | At least one failure mode named and responded to |
| Scope defined | 7 | Hard v1 / later line drawn |
| Features listed | 8 | At least one feature that traces to the bet |

Phases 1 and 4 are generative — they produce raw input, not gate-able artifacts. Don't gate on them.

Flag any gates that aren't met. The user decides whether to address them now or come back later.

## Challenging vs. Accepting

Push back when:
- The user states a problem without evidence ("everyone needs this")
- The brainstorm has fewer than three approaches
- The bet is vague ("this will help people")
- The stress test has no real failure modes ("I can't think of any")
- v1 scope is too large to test quickly

Accept and move on when:
- The user has given a concrete, specific answer even if you'd phrase it differently
- The user explicitly says "I've thought about this, let's move on"
- You've pushed back once and the user has responded — don't re-litigate

## Workflow

```
docs/ideas/     -> Ideas being refined (this protocol)
docs/features/  -> Fully defined features (graduated from ideas)
docs/tasks/*/*  -> Actionable work items (decomposed from features)
```
