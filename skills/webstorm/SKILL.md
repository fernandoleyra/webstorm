---
name: webstorm
description: Scaffold a 3-prototype static website workspace with brand ingestion, UX reference extraction, anti-AI-slop guardrails, and optional parallel build agents in isolated worktrees. Use when the user runs /webstorm or asks to scaffold a multi-prototype web design project.
---

# Webstorm Skill

You are the webstorm skill. Follow this checklist exactly. Use TodoWrite to track each step.

---

## How to read arguments

The user may have passed arguments via /webstorm:

- `--brief`         → skip wizard; write pre-filled webstorm-brief.md, instruct user to edit it, wait for 'continue'
- `--resume <path>` → load existing webstorm-brief.md at <path>, skip filled fields, continue from first empty one
- `--rebuild style-N` → re-dispatch builder for one prototype only (skip questionnaire)
- `--dry-run`       → run full wizard but print what would be written; do not create files
- `--reconfigure`   → re-run Phase 0 (plugin settings) only
- (no args)         → full wizard mode

---

## Phase 0 — Plugin settings

Read `.claude/webstorm.local.md` if it exists. If it does not exist (first run), run Q0.

**Q0 — First-run settings (only if .claude/webstorm.local.md is missing):**

Call AskUserQuestion with these three questions in one call:

1. header: "Base path" | question: "Where should /webstorm create new projects by default?" | options: ~/Developer/ | ~/Projects/ | ~/Sites/ | ~/Desktop/

2. header: "Date prefix" | question: "Use YYMMDD date prefix in project folder names? (e.g. 260520_ClientSlug)" | options: Yes (recommended) | No

3. header: "Dispatch mode" | question: "Default behavior after scaffolding?" | options: Scaffold only | Checkpoint dispatch (build + review) | Autonomous (build + auto-fix)

After answers, write `.claude/webstorm.local.md`:

```
---
base_path: <answer-to-Q0a>
default_use_tailwind_cdn: true
default_date_prefix: <true|false>
default_dispatch_mode: <scaffold-only|checkpoint|autonomous>
preferred_builder_model: sonnet
sniff_test_strictness: high
---

# Webstorm plugin settings
Edit the YAML above to change defaults. Run `/webstorm --reconfigure` to update via prompts.
```

---

## Phase 1 — Project basics

Call AskUserQuestion with 4 questions:

1. header: "Project name" | question: "Project / client name?" | options: [suggest cwd folder name if meaningful] [+ Custom]

2. header: "Purpose" | question: "What is the website's primary purpose?" | options: Lead generation | E-commerce | Brand storytelling | Product showcase | Service catalog | Editorial / content | Portfolio | Internal tool

3. header: "Audience" | question: "Who is the primary audience?" | options: General consumers | B2B decision-makers | Technical practitioners | Local community | Investors / press | Internal staff

4. header: "Success metric" | question: "What does success look like?" | options: Form submissions | Phone calls / WhatsApp | Bookings | Purchases | Newsletter signups | Time on site | Brand impression

Write answers to `webstorm-brief.md` as YAML frontmatter.

---

## Phase 2 — Brand

Call AskUserQuestion with 3 questions:

1. header: "Brand URL" | question: "Client website URL? (paste URL or type 'none')" | options: none [+ Custom URL]

2. header: "Brand assets" | question: "Do you have local brand files to provide? (logo, brand book PDF, palette swatches)" | options: Yes | No

3. header: "Voice / tone" | question: "Pick up to 3 words that describe the brand's voice and tone." | multiSelect: true | options: Authoritative | Warm | Playful | Technical | Editorial | Restrained | Confident | Cheeky

**If user provided a URL (not 'none'):**
- Use the firecrawl skill or Firecrawl MCP tools to scrape the URL.
- Extract ONLY: navigation structure (IA), content section ordering, interaction patterns, copy tone.
- Do NOT extract: colors, typefaces, or visual design tokens.
- Write findings to `brand/voice.md` under heading "IA observations from <url>".

**If user answered Yes to brand assets:**
- Determine base_path from plugin settings + project name.
- Create the project folder + `assets/` directory NOW (early creation for asset drop).
- Print exactly: "Drop your brand files into `<full-path>/assets/` then reply `continue`."
- Wait for user to reply 'continue'.
- After continue, scan `assets/`:
  - Files with 'logo' in name + .svg/.png/.jpg → record as logo, note dominant colors.
  - .pdf files → read as text, extract color mentions, typeface mentions, voice guidelines.
  - .ai / .psd / .fig → note as "design source, not parsed."
- Synthesize `brand/tokens.css` from scan findings.
- Synthesize `brand/voice.md` from scan findings + URL scrape (if both present, merge).

**If no URL and no local files (greenfield):**
- Generate a draft brand:
  - Pick a non-Inter, non-system-ui typographic pairing
  - Pick a 6-color palette based on voice/tone choices
  - Write `brand/tokens.css` marked `/* DRAFT — replace before production */`
  - Write `brand/voice.md` with tone-derived copy direction
- Clearly label all generated content as DRAFT.

---

## Phase 3 — Shared page architecture

Call AskUserQuestion with 2 multi-select questions:

1. header: "Pages" | question: "Which pages does this site need?" | multiSelect: true | options: Home / Landing | About / Team | Services overview | Product / service detail | Inventory / Catalog | Pricing | Contact | Blog / News | Case studies | FAQ

2. header: "Features" | question: "Which features does the site need?" | multiSelect: true | options: Contact form | Booking / scheduler | Inventory filter + search | Image gallery | Video hero | Map embed | Newsletter signup | Cookie consent | Multi-language | Testimonials

Write answers to `webstorm-brief.md`.

---

## Phase 4 — Per-prototype (4 batched 3-slot prompts)

Each AskUserQuestion call covers all 3 prototypes simultaneously. This is exactly 4 calls.

**Q4a — Compositional commandments**

Call AskUserQuestion with 3 questions (one per prototype slot):

For each of style-1, style-2, style-3:
- header: "Style-N commandment"
- question: "Compositional commandment for style-N?"
- options: Editorial magazine grid | Brutalist single-column | Info-dense lock-up | Asymmetric collage | Centered classical | Swiss-grid functional | Cinematic full-bleed

**Q4b — Visual boldness temperatures**

Call AskUserQuestion with 3 questions (one per slot):
- header: "Style-N temp"
- question: "Visual boldness temperature for style-N (0=safe, 100=experimental)?"
- options: 20 | 40 | 60 | 80 | 100

**Q4c — References**

Call AskUserQuestion with 3 questions (one per slot, free text):
- header: "Style-N refs"
- question: "References for style-N (min 2: URLs, named brands, movements, eras). Vague adjectives rejected."
- options: [provide 3-4 example valid refs as options e.g. "https://stripe.com, Bauhaus" | "Bloomberg, 90s magazine" | "Massimo Vignelli, De Stijl"]

For each prototype's answer, validate with: `bash tests/reference-validator.sh "<refs>"`
If validation fails (exit 1), show the rejection reasons and ask again. Repeat until all pass.

**Q4d — Off-limits**

Call AskUserQuestion with 3 optional questions (one per slot):
- header: "Style-N off-limits"
- question: "Anything explicitly off-limits for style-N? (optional)"
- options: None | no dark mode | no carousels | no stock photography

Write all Phase 4 answers to `webstorm-brief.md`.

---

## Eager reference fetch

For each prototype's validated references:
- For each URL: scrape with Firecrawl. Extract: IA, interactions, layout grammar, content rhythm.
  Write to `references/style-N/<slug>.md` with sections:
  `## IA pattern`, `## Interaction moves`, `## Layout grammar`, `## Content rhythm`
  NO sections called `## Color` or `## Typography`.
- For brand/studio/designer names: write conceptual anchor (their known IA/UX approach, 1 paragraph).
- For art movements / eras: describe compositional and structural characteristics (1 paragraph). No color or typeface descriptions.
- For references that fail to scrape: write `references/style-N/_fetch-errors.md`. Ask user: retry / replace / skip.

---

## Phase 5 — Tech and dispatch

Call AskUserQuestion with 2 questions:

1. header: "Tailwind CDN" | question: "Use Tailwind CSS via CDN? (no build step, just a script tag)" | options: Yes, all prototypes | No, vanilla CSS only | Per-prototype (choose at build time)

2. header: "Dispatch" | question: "After scaffolding, what should happen?" | options: Scaffold only — I'll build manually | Build now (checkpoint — review after first pass) | Build now (autonomous — auto-fix, no interruptions)

Write answers to `webstorm-brief.md`.

---

## Scaffold file generation

If `--dry-run`, print the full list of files that would be written and exit.

Otherwise:

1. Determine project path: `<base_path>/<YYMMDD_ClientSlug>/<project-slug>/`
   If the project folder was already created in Phase 2 (for asset drop), use that path.
   If the name collides with an existing folder, prompt for a new name — never overwrite.

2. Create directory structure:
   ```
   <project>/
     assets/        (if not already created)
     brand/
     references/style-1/
     references/style-2/
     references/style-3/
     style-1/assets/
     style-2/assets/
     style-3/assets/
   ```

3. Render templates using `bash tests/template-rendering.sh webstorm-brief.md <project>/`
   (This renders scaffold.md, workflow.md, CLAUDE.md, brand/tokens.css, .gitignore)

4. Write `brand/voice.md` (from Phase 2 ingestion, URL scrape, or greenfield draft).

5. For each prototype n in (1, 2, 3):
   Read `skills/webstorm/templates/CLAUDE.prototype.md.tmpl`.
   Substitute:
   - {{n}} → the prototype number (1, 2, or 3)
   - {{project_name}} → from brief
   - {{commandment}} → Phase 4 Q4a answer for this prototype
   - {{temperature}} → Phase 4 Q4b answer
   - {{temperature_directive}} → the directive text from anti-ai-rules.md Measure 6 table matching the temperature
   - {{references_list}} → Phase 4 Q4c answer (validated)
   - {{off_limits}} → Phase 4 Q4d answer, or "None declared." if blank
   Write rendered content to `style-N/CLAUDE.md`.

6. Pre-commit self-check:
   - Every `style-N/CLAUDE.md` contains the prohibition list? → confirm
   - `brand/tokens.css` exists with no unfilled `{{` placeholders? → grep check
   - `references/style-N/` has at least one file per prototype? → confirm
   - `webstorm-brief.md` is complete (no empty required fields)? → confirm
   If any check fails, fix before committing.

7. Initialize git and commit:
   ```bash
   git init
   git add .
   git commit -m "scaffold from /webstorm — $(date +%Y-%m-%d)"
   ```

8. Print:
   ```
   ✓ Project scaffolded: <project-path>

   Preview each prototype:
     cd <project>-style-1 && python3 -m http.server 8001
     cd <project>-style-2 && python3 -m http.server 8002
     cd <project>-style-3 && python3 -m http.server 8003

   Or open directly:
     open <project>/style-1/index.html
   ```

---

## Dispatch branch

### Scaffold only
Exit after printing preview commands.

### Checkpoint dispatch

1. Invoke `superpowers:using-git-worktrees` to create 3 worktrees:
   - `<project>-style-1/` on branch `proto/style-1`
   - `<project>-style-2/` on branch `proto/style-2`
   - `<project>-style-3/` on branch `proto/style-3`

2. Read `skills/webstorm/dispatch/builder-prompt.md`.

3. Dispatch 3 Agent calls in ONE message (they run concurrently). For each n in (1, 2, 3):
   - Interpolate the builder prompt: replace {{n}}, {{project_name}}, {{worktree_path}}
   - Set model to sonnet if temperature < 80, opus if temperature ≥ 80
   - Call Agent with description="Build style-N: <project_name>", subagent_type="general-purpose"

4. Await all three returns.

5. For each prototype, dispatch a sniff-test agent:
   Agent(prompt="Run `bash tests/sniff-test.sh style-N/` in <worktree-path>. Return the full contents of style-N/_ai-tells.md verbatim.")
   Run all three in parallel.

6. Print summary per prototype: path, file count, sniff-test HIGH/MEDIUM severity.
   Invite user to review and decide: accept / iterate / rebuild one.

7. Exit.

### Autonomous dispatch

1–4. Same as Checkpoint.

5. For each prototype with HIGH sniff-test findings:
   Re-dispatch builder (same worktree, same branch) with original prompt + appended:
   "Your previous pass had these HIGH AI-tell findings:\n<findings>\nFix them without breaking the compositional commandment. Do not introduce new forbidden patterns."
   Run sniff test again.
   Repeat up to 3 total iterations per prototype.

6. Auto-commit final state on each worktree branch.

7. Print final summary and exit.

---

## Edge cases

- Re-invoked inside existing webstorm project (webstorm-brief.md found in cwd or ancestor): offer resume / new project / abort.
- All 3 builders flag same AI-tell: surface as a brand-level issue; offer to revise brand/tokens.css first.
- One builder times out or errors: flag it, continue with the other two, print rebuild command: `/webstorm --rebuild style-N`.
- Asset-drop 'continue' with empty assets/: warn ("no files detected; proceeding without local brand ingest") and continue.
- Non-git cwd: create new git repo at project path; do not touch cwd.
- Project folder name collision: prompt for new name; never overwrite.
- frontend-design skill not installed: continue with prohibition list only; note in final summary.
- Worktree creation blocked: surface the error; scaffold is already committed and safe; user can retry dispatch later.
