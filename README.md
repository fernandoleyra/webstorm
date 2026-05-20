# Webstorm

![version](https://img.shields.io/badge/version-0.1.0-blue)

Scaffold a 3-prototype static website workspace — with brand ingestion, UX reference
extraction, anti-AI-slop guardrails, and optional parallel build agents — in one command.

Inspired by a hand-built 3-prototype workflow for web design exploration.
This plugin operationalizes it for any project, any client, with your workplace.

---

## What it does

`/webstorm` runs a structured questionnaire, then:

1. **Ingests the client's brand** (CI/BI) — URL scrape, local asset files, or greenfield draft.
   The brand becomes the non-negotiable visual floor for all three prototypes.
2. **Fetches references** per prototype — UX/conceptual patterns only (layout grammar,
   information architecture, interaction patterns). Never visual mimicry.
3. **Scaffolds a project** with three peer prototype folders (`style-1/`, `style-2/`, `style-3/`),
   each with its own CLAUDE.md (rules), commandment, temperature, and reference set.
4. **Optionally dispatches three parallel build agents**, each in an isolated git worktree,
   producing genuinely independent first-pass designs.

---

## Install

```bash
/plugin marketplace add https://github.com/fernandoleyra/webstorm
/plugin install webstorm
```

---

## Usage

```
/webstorm                          # full wizard (recommended for first run)
/webstorm --brief                  # write editable brief file, then continue
/webstorm --resume <path>          # resume a partially-filled brief
/webstorm --rebuild style-2        # re-dispatch one prototype's builder
/webstorm --dry-run                # preview what would be written, no files created
/webstorm --reconfigure            # re-run plugin settings
```

---

## What gets generated

```
260520_ClientName/webproject/
  scaffold.md          ← project brief
  workflow.md          ← operating guide
  CLAUDE.md            ← shared governance + anti-AI prohibitions
  webstorm-brief.md    ← full questionnaire output
  assets/              ← drop logo, brand book here
  brand/
    tokens.css         ← brand color, type, spacing tokens (locked floor)
    voice.md           ← tone and copy direction
  references/
    style-1/<ref>.md   ← UX patterns extracted from your references
    style-2/<ref>.md
    style-3/<ref>.md
  style-1/             ← prototype 1 (its own CLAUDE.md, commandment, temp, refs)
  style-2/
  style-3/
```

When parallel build runs, three git worktrees are created alongside:

```
260520_ClientName/webproject-style-1/   (branch: proto/style-1)
260520_ClientName/webproject-style-2/   (branch: proto/style-2)
260520_ClientName/webproject-style-3/   (branch: proto/style-3)
```

---

## Anti-AI-slop philosophy

Out-of-the-box AI-generated websites are recognizable: Inter, slate-900, rounded-2xl
shadow-lg cards, purple-to-blue gradients, "Transform your workflow" hero copy.

This plugin fights that structurally, not stylistically:

1. **Concrete references required** — vague adjectives (modern, clean) are rejected.
   You must supply URLs, named brands, named designers, named movements.
2. **Prohibition list baked into every prototype** — Inter, Lucide, Tailwind default
   color scales, and generic copy patterns are forbidden at the file level.
3. **The `frontend-design` skill is invoked** (if installed) before any markup.
4. **A compositional commandment** per prototype forces real layout divergence.
5. **A sniff-test script** post-build catches forbidden patterns with exact line numbers.
6. **Temperature scales strictness, not freedom** — higher temperature = more aggressive
   deviation from defaults, not permission to hallucinate.
7. **Design tokens before markup** — builders commit `tokens.css` before any HTML.

---

## Configuration

Plugin settings live in `.claude/webstorm.local.md` (created on first run):

```yaml
---
base_path: ~/Developer/
default_use_tailwind_cdn: true
default_date_prefix: true
default_dispatch_mode: checkpoint
preferred_builder_model: sonnet
sniff_test_strictness: high
---
```

Run `/webstorm --reconfigure` to update via prompts.

---

## Tests

```bash
bash tests/run-all.sh
```

Covers: sniff-test detection, reference validation, template rendering against golden output.

---

## Version bump (maintainers)

```bash
bash scripts/bump-version.sh patch    # 0.1.0 → 0.1.1
bash scripts/bump-version.sh minor    # 0.1.0 → 0.2.0
bash scripts/bump-version.sh major    # 0.1.0 → 1.0.0
```

Every push to `main` must bump the version. Without a bump, `/plugin` reports
"already at latest" and teammates' sessions don't pick up changes.

---

## License

MIT
