# Webstorm

![version](https://img.shields.io/badge/version-0.1.0-blue) ![license](https://img.shields.io/badge/license-MIT-lightgrey)

Every AI-generated website looks the same. Inter, slate-900, rounded-2xl cards, a purple-to-blue gradient behind the hero, and copy that opens with "Transform your workflow."

Webstorm is a Claude Code plugin that makes that outcome structurally impossible. It runs a 5-phase wizard, ingests your client's brand, fetches real design references, and dispatches three parallel build agents — each locked to a different compositional commandment — into isolated git worktrees.

---

## How it works

`/webstorm` asks five rounds of questions, then:

1. **Ingests the brand** — URL scrape, local asset files, or greenfield draft. The result becomes `brand/tokens.css`: the non-negotiable visual floor every prototype must stand on.
2. **Fetches references per prototype** — layout grammar and information architecture patterns, not visual mimicry. Each prototype gets its own reference set.
3. **Scaffolds three peer prototype folders** (`style-1/`, `style-2/`, `style-3/`), each with its own CLAUDE.md, compositional commandment, temperature setting, and reference library.
4. **Commits `tokens.css` before any markup is written.** Builders cannot proceed until the token floor exists.
5. **Optionally dispatches three parallel build agents**, each in an isolated git worktree on its own branch, producing genuinely independent first-pass designs.

A sniff-test script runs after each build and flags forbidden patterns — Inter, Lucide icons, Tailwind default color scales, generic hero copy — with exact line numbers.

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
/webstorm --brief                  # write an editable brief file, then continue
/webstorm --resume <path>          # resume a partially-filled brief
/webstorm --rebuild style-2        # re-dispatch one prototype's build agent
/webstorm --dry-run                # preview what would be written, no files created
/webstorm --reconfigure            # re-run plugin settings
```

---

## What gets scaffolded

```
260520_ClientName/webproject/
  scaffold.md              ← project brief
  workflow.md              ← operating guide
  CLAUDE.md                ← shared governance and anti-slop prohibitions
  webstorm-brief.md        ← full questionnaire output
  assets/                  ← drop logo and brand book here
  brand/
    tokens.css             ← color, type, spacing tokens (committed before any markup)
    voice.md               ← tone and copy direction
  references/
    style-1/<ref>.md       ← UX patterns extracted from your references
    style-2/<ref>.md
    style-3/<ref>.md
  style-1/                 ← prototype 1 (own CLAUDE.md, commandment, temperature, refs)
  style-2/
  style-3/
```

When parallel dispatch runs, three worktrees are created alongside:

```
260520_ClientName/webproject-style-1/   (branch: proto/style-1)
260520_ClientName/webproject-style-2/   (branch: proto/style-2)
260520_ClientName/webproject-style-3/   (branch: proto/style-3)
```

---

## Anti-slop measures

The problem with AI-generated sites is not style — it is that AI defaults to the same distribution of choices every time. Webstorm fights this structurally:

| Measure | What it does |
|---|---|
| Prohibition list in every CLAUDE.md | Inter, Lucide/Heroicons, Tailwind default color scales, `rounded-2xl shadow-lg` card patterns, and generic copy phrases are forbidden at the file level |
| Concrete references required | Vague adjectives (modern, clean, minimal) are rejected. You must supply URLs, named brands, named designers, or named movements |
| Compositional commandment per prototype | Each prototype is locked to a distinct layout grammar: Editorial magazine grid, Brutalist single-column, Swiss-grid functional, or others. Real divergence, not palette swaps |
| `frontend-design` skill invoked before markup | If the `frontend-design` plugin is installed, it runs its design-token and layout-intent phase before any HTML is written |
| Temperature as boldness, not randomness | Higher temperature = more aggressive deviation from defaults, not permission to produce noise |
| Sniff-test script post-build | Scans output for forbidden patterns and reports exact file paths and line numbers |

---

## Configuration

Plugin settings live in `.claude/webstorm.local.md`, created on first run:

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

Covers sniff-test detection, reference validation, and template rendering against golden output.

---

## Version bump (maintainers)

```bash
bash scripts/bump-version.sh patch    # 0.1.0 → 0.1.1
bash scripts/bump-version.sh minor    # 0.1.0 → 0.2.0
bash scripts/bump-version.sh major    # 0.1.0 → 1.0.0
```

Every push to `main` must bump the version. Without a bump, `/plugin` reports "already at latest" and teammates' sessions do not pick up the changes.

---

## License

MIT
