# Webstorm Skill — Design Spec

**Date:** 2026-05-20
**Author:** Leyra (with Claude)
**Status:** Approved — ready for implementation planning
**Inspired by:** `/Users/leyra/Developer/01_Web_Design/02_Family/260520_Volketswill_Car/auto-salon-website` (the working 3-prototype reference repo)

---

## 1. Goal

Build a Claude Code plugin — `webstorm` — that scaffolds a 3-prototype static website workspace from a structured questionnaire, ingests the client's brand identity as a non-negotiable visual floor, fetches references as UX/conceptual anchors (never visual mimicry), and optionally dispatches three parallel build agents in isolated git worktrees to produce three genuinely different first-pass designs.

The skill exists to make 3-prototype web exploration **fast, opinionated, and AI-slop-resistant**, and to be shareable with a workplace via a single plugin install.

## 2. Non-goals

- Not a CMS, deploy pipeline, or hosting tool.
- Not a build system (vanilla HTML/CSS/JS + optional Tailwind via CDN; no `npm`).
- Not a brand-identity generator (greenfield draft brand is a marked placeholder, not a deliverable).
- Not a design copier — references are UX/conceptual, the client's brand is the visual floor.
- Not autonomous past 3 iterations per prototype, never deploys, never pushes to GitHub.

## 3. User flow (end to end)

```
User types /webstorm in any Claude Code session
  └─ Skill loads
     ├─ Phase 0: resolve plugin settings (base path, defaults). First run → prompt + save.
     ├─ Phase 1: project basics (name, purpose, audience, success metric)
     ├─ Phase 2: brand
     │     ├─ Ask for brand URL directly (no search step). Optional.
     │     ├─ Ask if local brand assets exist (logo, brand book, swatches).
     │     ├─ If yes → create project folder + empty assets/ early.
     │     │   Print: "Drop files into <path>/assets/ then reply `continue`."
     │     │   Wait.
     │     ├─ Scan assets/, extract logo/colors/voice (PDFs read as text, SVG/PNG colors sampled).
     │     ├─ If URL given → Firecrawl + Playwright scrape, extract voice/IA only.
     │     └─ Synthesize brand/tokens.css + brand/voice.md.
     │         (Greenfield mode: generate draft brand, mark as placeholder.)
     ├─ Phase 3: shared page architecture + functional features (multi-select)
     ├─ Phase 4: per-prototype (4 batched prompts, each with 3 slots — one per style)
     │     ├─ Compositional commandment
     │     ├─ Visual boldness temperature (0–100)
     │     ├─ References (URLs / named brands / movements; min 2; adjectives rejected)
     │     └─ Off-limits (optional free text)
     ├─ Eager reference fetch (Firecrawl + Playwright) → references/<proto>/<ref>.md
     │     UX/conceptual extraction only — IA, interactions, layout grammar, content rhythm.
     │     Colors/typefaces/visual tokens explicitly skipped.
     ├─ Phase 5: tech stack + dispatch choice
     ├─ Write rest of scaffold (templates → real files, placeholders interpolated)
     ├─ git init + initial commit ("scaffold from /webstorm")
     ├─ Self-check: prohibition list present in every prototype CLAUDE.md? brand/tokens.css populated?
     └─ Branch on dispatch choice:
            scaffold-only        → done, print preview commands
            checkpoint dispatch  → create 3 worktrees → dispatch 3 builders in parallel
                                   → sniff-test each → print report → exit
            autonomous dispatch  → same + loop builder ↔ sniff-test up to 3× per prototype
```

## 4. Architecture

### 4.1 Distribution — Claude Code plugin

Repo: `/Users/leyra/Developer/03_AI_Agents/webstorm-plugin` (new public GitHub repo).

```
webstorm-plugin/
├── plugin.json                    # name, version (bumped every push), description
├── README.md                      # install + usage + version badge
├── LICENSE                        # MIT
├── .claude-plugin/
│   └── marketplace.json           # bare {source, url}, no `path` field
├── commands/
│   └── webstorm.md                # /webstorm slash command (thin shim → Skill)
├── skills/
│   └── webstorm/
│       ├── SKILL.md               # the skill body (process, checklist, references)
│       ├── questions.md           # full questionnaire reference
│       ├── anti-ai-rules.md       # 7 anti-slop measures, fully documented
│       ├── templates/             # files written into new projects
│       │   ├── scaffold.md.tmpl
│       │   ├── workflow.md.tmpl
│       │   ├── CLAUDE.root.md.tmpl
│       │   ├── CLAUDE.prototype.md.tmpl
│       │   ├── tokens.css.tmpl
│       │   └── .gitignore.tmpl
│       └── dispatch/
│           └── builder-prompt.md  # prompt sent to each parallel builder
├── scripts/
│   └── bump-version.sh            # one-command version + badge bump
└── tests/
    ├── run-all.sh
    ├── template-rendering.sh
    ├── sniff-test.sh
    └── reference-validator.sh
```

Plugin settings live per-user at `.claude/webstorm.local.md` (YAML frontmatter + markdown body, per the `plugin-settings` skill pattern).

Workplace install: `/plugin marketplace add <repo-url>` → `/plugin install webstorm`.

### 4.2 Generated project structure

```
<base>/<YYMMDD_ClientSlug>/<project-slug>/   ← git init here, this is the worktree root
  scaffold.md
  workflow.md
  CLAUDE.md                  (root governance — brand floor, shared prohibitions)
  webstorm-brief.md          (the filled questionnaire — single source of truth)
  assets/                    (root-level; user-dropped logos, brand book, swatches)
  brand/
    tokens.css               (brand CI/BI tokens — locked floor)
    voice.md
  references/
    style-1/<ref>.md         (UX-pattern extracts only)
    style-2/<ref>.md
    style-3/<ref>.md
  style-1/                   (each has its own CLAUDE.md from CLAUDE.prototype.md.tmpl)
    CLAUDE.md
    assets/                  (prototype-specific images, populated by builder)
  style-2/
    CLAUDE.md
    assets/
  style-3/
    CLAUDE.md
    assets/
  .gitignore
```

When dispatch runs, three worktrees are created as siblings of this folder:

```
<base>/<YYMMDD_Client>/<project>-style-1/   (branch: proto/style-1)
<base>/<YYMMDD_Client>/<project>-style-2/   (branch: proto/style-2)
<base>/<YYMMDD_Client>/<project>-style-3/   (branch: proto/style-3)
```

Each worktree contains the full project tree; each builder is scoped to write only inside its own `style-N/` folder.

### 4.3 Skill execution checklist (TodoWrite items at runtime)

1. Resolve base path (from `.claude/webstorm.local.md` or first-run prompt).
2. Phase 1 prompts → start `webstorm-brief.md`.
3. Phase 2 prompts → brand URL? brand assets locally? voice?
4. If URL given → scrape via Firecrawl + Playwright (text + IA, no visual tokens).
5. If local assets flagged → create project folder + `assets/` early → instruct drop → wait → scan.
6. Synthesize `brand/tokens.css` + `brand/voice.md`.
7. Phase 3 prompts → pages + features.
8. Phase 4 prompts → 4 batched 3-slot prompts (commandment / temperature / refs / off-limits).
9. Eager reference fetch → `references/<proto>/<ref>.md` (UX patterns only).
10. Phase 5 prompts → tech stack + dispatch choice.
11. Write all remaining scaffold files (templates interpolated).
12. `git init` + initial commit "scaffold from /webstorm".
13. Self-check: prohibition list in every prototype CLAUDE.md? `brand/tokens.css` populated? references present?
14. Branch on dispatch choice (scaffold-only / checkpoint / autonomous).
15. Final report: paths, preview commands, sniff-test summary.

### 4.4 Flow modes

- **Wizard mode** (default): 15 `AskUserQuestion` prompts (some batched 3-slot).
- **Brief mode** (`/webstorm --brief`): skill writes a pre-filled `webstorm-brief.md` in cwd; user edits in editor; reply `continue` triggers skip to step 9.
- **Resume mode** (`/webstorm --resume <path>`): picks up at first empty field.
- **Reconfigure mode** (`/webstorm --reconfigure`): re-prompts plugin settings.
- **Rebuild mode** (`/webstorm --rebuild style-N`): re-dispatches only one prototype's builder.
- **Dry-run mode** (`/webstorm --dry-run`): prints what would be written, exits without writing.

## 5. Anti-AI-slop guardrails (seven measures)

1. **Mandatory concrete references.** Phase 4 references field rejects vague adjectives (`modern`, `clean`, `minimal`, `sleek`, `professional`, `elegant`, `simple`). Accepts URLs, named brands, named designers/studios, named typefaces, named movements (Bauhaus, Brutalism, Swiss), named eras. Minimum 2 per prototype.

2. **Prohibition list in every prototype `CLAUDE.md`.** Verbatim block covering forbidden typography (`Inter`, `system-ui`), forbidden colors (Tailwind default scales as brand color, purple-to-blue gradients), forbidden composition (centered hero clichés, `rounded-2xl shadow-lg` cards), forbidden iconography (Lucide, Heroicons by default), forbidden copy patterns ("Transform your...", "Built for...", "The future of...").

3. **`frontend-design` skill invocation (soft dependency).** Each builder dispatch prompt instructs: *"Before writing markup, invoke `frontend-design:frontend-design` if available."* Falls back to prohibition list alone if not installed.

4. **Compositional commandment per prototype.** Each prototype's CLAUDE.md includes a binding layout law (editorial magazine grid / brutalist single-column / info-dense lock-up / asymmetric collage / centered classical / Swiss-grid functional / cinematic full-bleed / custom). Forces structural divergence between prototypes.

5. **AI-tell sniff test.** Post-build, a second subagent (no shared context with builder) greps for known tells (`Inter`, `slate-*`, `rounded-2xl`, `lucide`, "Transform your", purple gradients) and structural patterns (centered hero + h1 + two anchors). Writes `style-N/_ai-tells.md` with findings + severity. Autonomous mode re-dispatches builder with findings appended.

6. **Temperature → stricter, not looser.** Per-prototype temperature (0–100) maps to anti-default strictness, not creative freedom:
   - 20: stay close to safe corporate norms
   - 40: confident but restrained
   - 60: distinctive — at least 2 unconventional choices
   - 80: bold — push type/scale/layout aggressively
   - 100: experimental — reject any default; if a section looks like 100 other websites, redo it

7. **Design tokens before markup.** Builder's first step is non-negotiable: write `style-N/tokens.css` (named colors, type scale, spacing rhythm, radii) derived from `brand/tokens.css` (locked floor) + commandment + temperature. Markup work is blocked until tokens.css exists.

## 6. Build dispatch (parallel agents)

When dispatch is selected (Phase 5 Q15 = checkpoint or autonomous):

### 6.1 Worktree creation

Delegated to `superpowers:using-git-worktrees`. Creates three siblings of the project root, each on its own branch (`proto/style-1/2/3`). Predictable, persistent naming so the user can re-enter days later — not Agent-tool's auto-temporary worktrees.

### 6.2 Concurrent dispatch

Three `Agent` calls in a **single message** → run truly concurrently. Each subagent receives an isolated context window (no cross-pollination between siblings); the parent only sees final return messages. Each agent's write surface is scoped to its own worktree; cannot accidentally stomp on siblings.

### 6.3 Builder prompt (template — interpolated per prototype)

```
You are building style-N of <project>. Worktree: <path>.

Step 0 — read all of these before writing anything:
         scaffold.md, workflow.md, CLAUDE.md (root),
         style-N/CLAUDE.md (scripture), brand/tokens.css, brand/voice.md,
         references/style-N/*.md

Step 0.5 — invoke skill (if available): frontend-design:frontend-design

Step 1 — write style-N/tokens.css derived from brand/tokens.css + your
         compositional commandment + temperature. Do NOT write markup
         before this file exists.
Step 2 — write style-N/index.html and other pages per webstorm-brief.md.
Step 3 — write style-N/styles.css using your tokens. Reference brand tokens
         via CSS custom properties; never hardcode.
Step 4 — write style-N/main.js for declared functionality only.

Constraints: every "Forbidden defaults" entry in your CLAUDE.md is binding.
Your temperature directive is binding. Your compositional commandment is
binding.

Self-check before returning: open each HTML file, confirm tokens are used,
confirm no forbidden patterns leaked in.

Commit on branch proto/style-N with message "first-pass style-N".
Report: files created, deviations from brief, blockers.
```

Model: `sonnet` for temperatures < 80; `opus` for temperatures ≥ 80.

### 6.4 Mode divergence

- **Checkpoint:** parent runs sniff test on all three (parallel) → prints per-prototype severity → exits. User decides.
- **Autonomous:** for each prototype with high-severity findings, re-dispatch builder with findings appended. Max 3 iterations per prototype. Then auto-commit + exit.

### 6.5 Preview

Skill prints exact commands:

```
cd <project>-style-1 && python3 -m http.server 8001
cd <project>-style-2 && python3 -m http.server 8002
cd <project>-style-3 && python3 -m http.server 8003
```

Plus direct-open fallbacks (`open <path>/index.html`).

## 7. Edge cases & failure modes

1. Re-running `/webstorm` inside an existing webstorm project → offer resume / new / abort.
2. Mid-wizard abort → persisted progress; `--resume` picks up at first empty field.
3. Brand URL scrape fails → retry / manual paste / greenfield.
4. Reference fetch partial failure → `_fetch-errors.md`; user decides per-ref.
5. Fewer than 2 valid references → prompt re-asks with reason.
6. Asset-drop continue with empty `assets/` → warn + continue.
7. Large PSD/AI dropped → recorded as design-source, not parsed.
8. Worktree conflict → safety check stops dispatch; scaffold preserved; user retries.
9. One builder fails → others complete; failed prototype scaffolded-but-empty; `--rebuild style-N`.
10. All three flag same tell → surface as brand-level issue; offer brand revision.
11. Non-git cwd → skill creates new git repo at project path; never touches cwd.
12. Project-name collision → prompt for new name; never overwrite.
13. Builder hardcodes forbidden Tailwind defaults → sniff test catches it.
14. `frontend-design` skill missing → falls back to prohibition list.

**Boundaries (deliberately not done):** no deploy, no git push, no `npm install`, no edits outside the new project folder, no edits to `~/.claude/CLAUDE.md`, no unbounded loops (autonomous capped at 3 iterations per prototype).

## 8. Testing

Tests live in `tests/`, run via `bash tests/run-all.sh`. Not bundled into the installed plugin.

1. **Template rendering** — fixed brief → snapshot output → diff against golden.
2. **Sniff test** — known-bad and known-good HTML/CSS samples; assert detection.
3. **Reference validator** — adjectives vs URLs vs brand names vs movements; assert pass/fail.
4. **Dry-run** — `/webstorm --dry-run` prints what would be written without writing.
5. **Manual end-to-end** — run against the auto-salon brief; compare against the hand-built reference repo.

## 9. Plugin settings (`.claude/webstorm.local.md`)

```markdown
---
base_path: /Users/leyra/Developer/01_Web_Design
default_use_tailwind_cdn: true
default_date_prefix: true
default_dispatch_mode: checkpoint    # checkpoint | autonomous | scaffold-only
preferred_builder_model: sonnet      # sonnet | opus
sniff_test_strictness: high          # low | medium | high
---

# Webstorm plugin settings

Edit the YAML above to change defaults. Run `/webstorm --reconfigure` to
update via prompts.
```

First run writes this file via a one-time prompt. Subsequent runs read it silently.

## 10. Distribution lifecycle

- **Versioning:** `plugin.json.version` + README badge bumped on every push (per `feedback_plugin_version_bump.md`). `scripts/bump-version.sh` makes it one command.
- **Marketplace:** single-plugin, bare `{source, url}` form, no `path` field (per `feedback_plugin_marketplace_source.md`).
- **Workplace install:** `/plugin marketplace add <repo-url>` → `/plugin install webstorm`.
- **License:** MIT.
- **No telemetry.**

## 11. Assumptions (flagged for confirmation in the brainstorm; all approved)

- A. `frontend-design` is a soft dependency (recommended, not required).
- B. Preview uses `python3 -m http.server` — Python 3 expected in workplace.
- C. Plugin repo is **public** GitHub (private works the same, requires SSH).
- D. License: MIT.
- E. No telemetry.

## 12. Open questions (none blocking implementation)

- Exact content of the `frontend-design` skill invocation prompt — to be drafted during implementation.
- Whether `--rebuild style-N` should also re-run the sniff test or only the builder — default: yes, re-run sniff test; revisit if it surfaces an issue.
- Sniff-test severity thresholds — start with "high = any forbidden default present", "medium = clichéd composition without a forbidden default", "low = stylistic preference"; tune in real use.

## 13. Implementation plan trigger

This spec is the input to the `superpowers:writing-plans` skill, which will produce a step-by-step implementation plan covering: repo init, plugin.json + marketplace.json, command + skill files, templates, dispatch prompt, sniff-test logic, settings handler, tests, README + version bump script. That plan is the artifact for actual code work.
