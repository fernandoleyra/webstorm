# Webstorm Builder Dispatch Prompt

This file is the template for the prompt sent to each prototype-builder subagent.
The parent skill (SKILL.md) interpolates {{n}}, {{project_name}}, {{worktree_path}},
and {{model}} before dispatching via the Agent tool.

---

You are building style-{{n}} for the project "{{project_name}}".

Your working directory (worktree): {{worktree_path}}

## Step 0 — Read all of these before writing anything

- `scaffold.md` — project brief and requirements
- `workflow.md` — folder model and operating order
- `CLAUDE.md` (root) — shared governance and anti-slop prohibitions
- `style-{{n}}/CLAUDE.md` — YOUR prototype rules. This is scripture.
- `brand/tokens.css` — brand design tokens (the visual floor)
- `brand/voice.md` — tone and copy direction
- `references/style-{{n}}/*.md` — extracted UX patterns from your references

## Step 0.5 — Invoke frontend-design skill if available

If `frontend-design:frontend-design` is available in your session, invoke it now.
Follow its guidance alongside your prototype's CLAUDE.md rules.

## Step 1 — Write style-{{n}}/tokens.css

Derive from `brand/tokens.css` (locked floor) + your compositional commandment + temperature.
Define named CSS custom properties for:
- Colors specific to this prototype (building on, not overriding, brand colors)
- Typefaces (must differ from Inter/system-ui/apple-system — use a named, character-ful face)
- Type scale (at minimum: --type-scale-xs through --type-scale-2xl)
- Spacing rhythm (at minimum: --space-xs through --space-2xl)
- Any prototype-specific shape tokens (border-radius, etc.)

**Do NOT write any HTML before this file is committed.**

```bash
git add style-{{n}}/tokens.css
git commit -m "tokens: style-{{n}} design token foundation"
```

## Step 2 — Build pages

Write `style-{{n}}/index.html` and other pages listed in `webstorm-brief.md`.
Use only CSS custom properties from `style-{{n}}/tokens.css` and `brand/tokens.css`.
No hardcoded hex values. No hardcoded pixel sizes for type (use the type scale).

Every page must:
- Reference `style-{{n}}/styles.css`
- Reference `style-{{n}}/main.js` (even if it only contains a comment)
- Be independently browseable (all links resolve within style-{{n}}//)

## Step 3 — Write style-{{n}}/styles.css

Reference only custom properties from your tokens.css and brand/tokens.css.
Honor your compositional commandment at every section.
The header/nav/hero must clearly express the commandment — this is where the
design identity lives.

## Step 4 — Write style-{{n}}/main.js

Implement only the features declared in `webstorm-brief.md` under "Functional features".
No extra functionality. Comment each feature with a one-line description.

## Step 5 — Self-check and sniff test

1. Open each HTML file mentally — are brand tokens consumed everywhere?
2. Run: `bash tests/sniff-test.sh style-{{n}}/`
3. Fix ALL HIGH findings before proceeding.
4. Commit fixes.

## Step 6 — Final commit

```bash
git add style-{{n}}/
git commit -m "first-pass style-{{n}}"
```

## Step 7 — Report back

Return a report containing:
- Files created (list)
- Temperature honored (yes/no, how)
- Compositional commandment: where it was expressed most strongly
- Any deviations from the brief and why
- Any HIGH sniff-test findings that could not be resolved (explain why)
- Blockers (if any)

---

## Isolation reminder

You write ONLY inside `style-{{n}}/`. The folders `style-1/`, `style-2/`, `style-3/`
(whichever are not yours) are read-only context. Do not modify root-level files
(scaffold.md, workflow.md, CLAUDE.md, brand/, references/) — those are shared and
committed at scaffold time.
