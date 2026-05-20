---
name: webstorm
description: Use when running /webstorm or asked to scaffold a multi-prototype web design project. Handles brand ingestion, reference extraction, anti-AI-slop guardrails, and Google Stitch prompt generation per prototype.
---

# Webstorm Skill

You are the webstorm skill. Follow this checklist exactly. Use TodoWrite to track each step.

---

## How to read arguments

- `--brief`         → skip wizard; write pre-filled webstorm-brief.md, instruct user to edit it, wait for 'continue'
- `--resume <path>` → load existing webstorm-brief.md at <path>, skip filled fields, continue from first empty one
- `--rebuild style-N` → re-generate Stitch prompt for one prototype only (skip questionnaire)
- `--dry-run`       → run full wizard but print what would be written; do not create files
- `--reconfigure`   → re-run Phase 0 (plugin settings) only
- (no args)         → full wizard mode

---

## Phase 0 — Plugin settings

Read `.claude/webstorm.local.md` if it exists. If it does not exist (first run), run Q0.

**Q0 — First-run settings (only if .claude/webstorm.local.md is missing):**

Call AskUserQuestion with these two questions in one call:

1. header: "Base path" | question: "Where should /webstorm create new projects by default?" | options: ~/Developer/ | ~/Projects/ | ~/Sites/ | ~/Desktop/

2. header: "Date prefix" | question: "Use YYMMDD date prefix in project folder names? (e.g. 260520_ClientSlug)" | options: Yes (recommended) | No

After answers, write `.claude/webstorm.local.md`:

```
---
base_path: <answer-to-Q0a>
default_date_prefix: <true|false>
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
- Use Playwright (navigate + snapshot) or the Firecrawl skill to scrape the URL.
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

Validate each answer: reject if it contains only vague adjectives from anti-ai-rules.md Measure 1.
If validation fails, show rejection reasons and ask again. Repeat until all pass.

**Q4d — Off-limits**

Call AskUserQuestion with 3 optional questions (one per slot):
- header: "Style-N off-limits"
- question: "Anything explicitly off-limits for style-N? (optional)"
- options: None | no dark mode | no carousels | no stock photography

Write all Phase 4 answers to `webstorm-brief.md`.

---

## Eager reference fetch

For each prototype's validated references:
- For each URL: scrape with Playwright or Firecrawl. Extract: IA, interactions, layout grammar, content rhythm.
  Write to `references/style-N/<slug>.md` with sections:
  `## IA pattern`, `## Interaction moves`, `## Layout grammar`, `## Content rhythm`
  NO sections called `## Color` or `## Typography`.
- For brand/studio/designer names: write conceptual anchor (their known IA/UX approach, 1 paragraph).
- For art movements / eras: describe compositional and structural characteristics (1 paragraph). No color or typeface descriptions.
- For references that fail to scrape: write `references/style-N/_fetch-errors.md`. Ask user: retry / replace / skip.

---

## Phase 5 — Export format

Call AskUserQuestion with 1 question:

1. header: "Stitch export" | question: "Which framework should the Google Stitch prompts target for export?" | options: HTML/CSS (no framework — recommended) | Tailwind CSS | Vue.js | Angular

Write answer to `webstorm-brief.md`.

---

## Scaffold file generation

If `--dry-run`, print the full list of files that would be written and exit.

Otherwise:

1. Determine project path: `<base_path>/<YYMMDD_ClientSlug>/`
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
     style-1/
     style-2/
     style-3/
   ```

3. Write `brand/voice.md` (from Phase 2 ingestion, URL scrape, or greenfield draft).

4. Write `brand/tokens.css` (from Phase 2, or DRAFT if greenfield).

5. Write `.gitignore` with `node_modules/` and `.DS_Store`.

6. Pre-commit self-check:
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

8. Create 3 branches and 3 worktrees:
   ```bash
   git branch proto/style-1
   git branch proto/style-2
   git branch proto/style-3
   git worktree add ../<project-slug>-style-1 proto/style-1
   git worktree add ../<project-slug>-style-2 proto/style-2
   git worktree add ../<project-slug>-style-3 proto/style-3
   ```

---

## Google Stitch Prompt Generation

For each prototype n in (1, 2, 3), synthesize one Google Stitch prompt and write it to `style-N/STITCH_PROMPT.md` in the worktree. Commit each file to its branch.

### Stitch prompt structure

Each prompt must include all 8 blocks below. Pull values from `webstorm-brief.md`, `brand/tokens.css`, `brand/voice.md`, and the `references/style-N/` files.

**Block 1 — Project context (2–3 sentences)**
Who the client is, what the site is for, who the audience is, and the success metric. Use facts from Phase 1, not marketing language.

**Block 2 — Vibe & references**
List the validated references from Q4c, with 1-sentence description of what to borrow from each (IA pattern, layout grammar, rhythm — NOT color or typeface). State the compositional commandment verbatim.

**Block 3 — Color system**
List every token from `brand/tokens.css` as `Token name: #HEXVAL — role`. If tokens are DRAFT, mark them as such and instruct Stitch to use them as a starting point, not a locked floor.

**Block 4 — Typography direction**
Propose 2–3 font pairings to explore, chosen to complement the brand and commandment. Never propose Inter, system-ui, or -apple-system as the primary display face. Map each font to a role (display heading / body / UI label). Note: do not lock one pairing — Stitch should show the best one.

**Block 5 — Screen list**
List up to 5 screens in order (from Phase 3 page selection). For each screen:
- Screen name
- Key sections / components it must contain
- Any screen-specific layout instruction

**Block 6 — Actual content**
Provide real copy, real product names, real prices, real addresses — whatever was established during brand ingestion. Mark invented placeholder values clearly as `[PLACEHOLDER]`. This block prevents Lorem Ipsum and generic AI fill.

**Block 7 — Explicitly forbidden**
Copy the applicable prohibitions from anti-ai-rules.md Measures 1–4 and append the prototype's Q4d off-limits list. Phrase as direct negative instructions ("Do not use...", "Never use...").
Always include these universal forbids:
- Do not use Inter, system-ui, or -apple-system as the primary typeface
- Do not use Tailwind default color scales (slate-*, zinc-*, gray-*, indigo-*) as brand colors
- Do not use purple-to-blue, pink-to-orange, or teal-to-pink gradients
- Do not use a centered hero with headline / subtitle / two CTAs as the default layout
- Do not use rounded-2xl shadow-lg card pattern
- Do not use Lucide, Heroicons, or Font Awesome icons by default
- Do not write copy with "Transform your...", "Built for...", "The future of...", "Empower your..."

**Block 8 — Export instruction**
"Export as <framework from Phase 5>. Deliver a single self-contained file per screen."

### Temperature → tone instruction

Append the matching directive from anti-ai-rules.md Measure 6 table at the end of Block 2:

| Temperature | Append to Block 2 |
|-------------|-------------------|
| 0–25  | "Stay close to safe corporate norms. No surprises." |
| 26–45 | "Confident but restrained. Avoid clichés. Do not intentionally surprise." |
| 46–65 | "Distinctive. Make at least 2 unconventional compositional choices." |
| 66–85 | "Bold. Push type scale, layout asymmetry, and color aggressively. Justify each choice." |
| 86–100 | "Experimental. Reject any default. If a section looks like 100 other websites, redo it." |

---

## Output to user

After writing all 3 `STITCH_PROMPT.md` files and committing them, print:

```
✓ Scaffolded: <project-path>
✓ 3 Google Stitch prompts generated — one per prototype

──────────────────────────────────────────────────
NEXT STEPS
──────────────────────────────────────────────────
1. Open https://stitch.withgoogle.com
2. For each prototype, paste the prompt from:
     style-1/STITCH_PROMPT.md  →  Prototype 1: <commandment-1>
     style-2/STITCH_PROMPT.md  →  Prototype 2: <commandment-2>
     style-3/STITCH_PROMPT.md  →  Prototype 3: <commandment-3>
3. Use Stitch's 5-screen mode to generate all screens at once.
4. Export as <export-format> and download.
5. Drop exported files into the matching style-N/ worktree directory.
6. Return here and run `/webstorm --rebuild style-N` for each prototype
   to run the sniff test and commit the final build.
──────────────────────────────────────────────────
```

Then print each prompt inline in a fenced markdown block so the user can read and copy directly without opening files.

---

## Post-Stitch handoff (`--rebuild style-N`)

When user returns with Stitch exports and runs `/webstorm --rebuild style-N`:

1. Scan `style-N/` for exported HTML/CSS/JS files.
2. Run sniff test: check for Measure 2 violations (Inter, forbidden gradients, etc.) in the exported code.
3. If HIGH violations found: print a targeted fix list and ask user whether to fix manually or re-prompt Stitch.
4. If clean (or after fixes): `git add style-N/ && git commit -m "build: style-N Stitch export"` on that worktree's branch.
5. Print: "style-N committed. Open: `open <worktree-path>/index.html`"

---

## Edge cases

- Re-invoked inside existing webstorm project (webstorm-brief.md found in cwd or ancestor): offer resume / new project / abort.
- All 3 Stitch prompts flag same AI-tell after export: surface as a brand-level issue; offer to revise brand/tokens.css and regenerate prompts.
- Asset-drop 'continue' with empty assets/: warn ("no files detected; proceeding without local brand ingest") and continue.
- Non-git cwd: create new git repo at project path; do not touch cwd.
- Project folder name collision: prompt for new name; never overwrite.
- Worktree creation blocked: surface the error; scaffold is intact; print: "Worktree creation failed: <reason>. Your scaffold is at <project-path>. Retry with `/webstorm --rebuild style-N` once resolved."
