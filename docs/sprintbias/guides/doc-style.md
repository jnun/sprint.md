# Doc Style

How to write a doc in this project so a reader — person or agent — spends the
fewest characters to learn the most. Put a doc in `docs/guides/`. This guide
obeys its own rules; read it as the example.

## Shape

Concern		Standard
Structure	`##` headings only. Nothing nested deeper than a heading.
Grouping	A table, never a bulleted or numbered outline.
Prose		One or two short lines between tables. Say the point, stop.
Length		Cut every word the reader already knows.

## Tables

A table is the default. It packs more per line than prose and lines up in the
raw file, so an agent reads it in one pass.

Rule		Do
Format		Tab-delimited. Type one tab between cells; prettydoc pads the rest.
Header		First row names the columns. No `---` row beneath it.
Cells		Plain text. Keep backticks in prose, out of cells.
Empty cell	End the row early. No trailing tabs to chase.
Framing		A blank line above and below. Nothing tabless touches the block.

## Align

Alignment lives in the file, not the viewer, so it takes one command and one
setting.

Step	How
Write	Put a single tab between cells. Do not hand-count padding.
Align	Run `./docs/sprintbias/scripts/prettydoc.py <file>` — it repads every stop.
Set		Tab width 4 in your editor. Vim: `:set tabstop=4`. VS Code is 4 already.

prettydoc turns one tab into shared stops — shorter cells get more tabs, longer
cells fewer — so every column lands on the same stop. At width 8 the longest
cell shears, so keep the editor at 4.

## Voice

Trait		Meaning
Common		Plain words that read the same to people and agents.
Positive	State the path as the rule. Name the thing to do.
Flat		One idea per line. A line that needs a sub-point needs its own line.
Short		A doc is context cost. Every extra line taxes the next reader.

## Plain, Not Decorated

These rules cover every authored file — the guides here and the work items under
`docs/tasks`, `docs/bugs`, `docs/features`, `docs/ideas`. Plain text is the
format. Decoration that carries no data is noise the next reader pays for.

Element			Rule
Emoji/icons		None as labels, bullets, or status. The words carry the meaning.
Color/badges	No HTML color, `<span>`, `style=`, or badge markup. Text only.
Drawn art		No ASCII boxes or divider bars. A blank line or a `##` heading separates.
Real output		A tool's own line (`✓ CLAUDE.md ensured`) is data. Keep it in backticks.

Quoting a tool's real output is data — keep it in backticks. Everything else is
words on the page.

## For Agents

When you author or edit a doc with a table, format it before you finish.

Trigger					Action
Wrote a table			Separate cells with one tab, then run prettydoc on the file.
Edited a table			Re-run prettydoc — a changed cell shifts the stops.
Wrote long cells		Prefer a short paragraph. A table is not a cage.
Reaching for an icon	Use the word instead. Decoration carries no data.

## When To Break It

A table of long free-text cells reads worse than a short paragraph. When a
thought won't compress into a cell, write the sentence. The standard serves the
reader; it is not a rule to satisfy.
