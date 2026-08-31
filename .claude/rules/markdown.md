# Rule — Markdown (`*.md`)

## Language

**English**, everywhere in this repository. The French wiki that documents
upstream NextUI lives outside the repo and is not governed by this rule.

## Be concise

Documentation here is a reference, not a narrative.

- Lead with the answer. No preamble, no restatement of the question.
- Prefer a table over three paragraphs. Prefer a code block over describing code.
- One idea per section. If a heading needs an "and", it is two sections.
- Say the thing that is not obvious from reading the source. Do not paraphrase
  code that the reader can open.
- Give numbers when they exist: file sizes, line counts, hunk counts. They are
  what make a claim checkable.
- No "Note that", "It is important to", "As we can see", "Simply", "Just".

## Structure

- One `#` H1 per file, matching what the file is about.
- A short index table at the top of any document over ~150 lines.
- Reference code as `path/to/file.c:123` — precise, and clickable in editors.

## Diagrams

Mermaid, in a fenced ` ```mermaid ` block, **rendered by GitHub**. That constrains
what is allowed:

- Supported types only: `graph` / `flowchart`, `sequenceDiagram`, `stateDiagram-v2`,
  `classDiagram`, `erDiagram`, `gantt`, `pie`. Nothing newer.
- No `%%{init}%%` directives, no custom themes, no `click` handlers — GitHub
  strips or ignores them.
- Quote any label containing punctuation, parentheses or `<br/>`:
  `A["nextui.elf (launcher)"]`.
- Keep node ids short and alphanumeric; put the prose in the label.
- A diagram earns its place by showing a mechanism the text cannot. Do not draw
  a box per directory.

## Do not

- No emoji in headings, no decorative badges.
- No status sections that will silently go stale ("currently working on…").
- No duplicating upstream `PAKS.md` / `HOOKS.md`; link to them instead.
