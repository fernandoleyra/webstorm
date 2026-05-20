# Webstorm Plugin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin (`webstorm`) that scaffolds a 3-prototype static website workspace, ingests brand assets, fetches UX references, enforces anti-AI-slop guardrails, and optionally dispatches three parallel build agents in isolated git worktrees.

**Architecture:** A thin `/webstorm` slash command triggers the `webstorm` skill. The skill drives the full lifecycle: questionnaire → brand ingestion → reference fetch → scaffold generation → optional parallel dispatch. Plugin ships with 6 scaffold templates, a builder dispatch prompt, a bash sniff-test script, and a reference validator script. Settings persist per-user in `.claude/webstorm.local.md`.

**Tech Stack:** Claude Code plugin (markdown skills + commands), bash (tests + scripts), `sed` for template rendering, Firecrawl + Playwright for reference/brand scraping at Claude runtime.

**Repo:** `/Users/leyra/Developer/03_AI_Agents/webstorm-plugin/` (already git-initialized, pushed to https://github.com/fernandoleyra/webstorm)

---

## File Map

```
webstorm-plugin/
├── plugin.json                              ← Task 1
├── .gitignore                               ← Task 1
├── .claude-plugin/
│   └── marketplace.json                     ← Task 1
├── commands/
│   └── webstorm.md                          ← Task 2
├── skills/
│   └── webstorm/
│       ├── anti-ai-rules.md                 ← Task 3
│       ├── questions.md                     ← Task 4
│       ├── SKILL.md                         ← Task 10  (depends on T3, T4, T7, T9)
│       ├── templates/
│       │   ├── scaffold.md.tmpl             ← Task 7
│       │   ├── workflow.md.tmpl             ← Task 7
│       │   ├── CLAUDE.root.md.tmpl          ← Task 7
│       │   ├── CLAUDE.prototype.md.tmpl     ← Task 7  (depends on T3)
│       │   ├── tokens.css.tmpl              ← Task 7
│       │   └── .gitignore.tmpl              ← Task 7
│       └── dispatch/
│           └── builder-prompt.md            ← Task 9  (depends on T3)
├── tests/
│   ├── run-all.sh                           ← Task 5
│   ├── sniff-test.sh                        ← Task 5  (TDD: before templates)
│   ├── reference-validator.sh               ← Task 6  (TDD: before skill)
│   ├── template-rendering.sh                ← Task 8  (depends on T7)
│   └── fixtures/
│       ├── bad-prototype/index.html         ← Task 5
│       ├── bad-prototype/styles.css         ← Task 5
│       ├── good-prototype/index.html        ← Task 5
│       ├── good-prototype/styles.css        ← Task 5
│       ├── sample-brief.md                  ← Task 8
│       └── golden/                          ← Task 8
│           ├── scaffold.md
│           ├── workflow.md
│           ├── CLAUDE.md
│           ├── tokens.css
│           └── .gitignore
├── scripts/
│   └── bump-version.sh                      ← Task 11
└── README.md                                ← Task 11
```

---

## Task 1: Repo scaffolding (plugin.json, marketplace, .gitignore)

**Files:**
- Create: `plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `.gitignore`

- [ ] **Step 1: Create plugin.json**

```json
{
  "name": "webstorm",
  "version": "0.1.0",
  "description": "Scaffold a 3-prototype static website workspace with anti-AI-bias guardrails and parallel build agents.",
  "author": "Leyra",
  "homepage": "https://github.com/fernandoleyra/webstorm"
}
```

- [ ] **Step 2: Create .claude-plugin/marketplace.json**

```bash
mkdir -p .claude-plugin
```

```json
{
  "name": "webstorm-marketplace",
  "plugins": [
    {
      "source": "url",
      "url": "https://github.com/fernandoleyra/webstorm"
    }
  ]
}
```

No `"path"` field — single-plugin marketplace requires bare `{source, url}` form.

- [ ] **Step 3: Create .gitignore**

```
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp
*.swo

# Test output
tests/tmp-output/
tests/fixtures/bad-prototype/_ai-tells.md
tests/fixtures/good-prototype/_ai-tells.md
```

- [ ] **Step 4: Commit**

```bash
git add plugin.json .claude-plugin/ .gitignore
git commit -m "feat: plugin manifest, marketplace, gitignore"
```

---

## Task 2: Command file

**Files:**
- Create: `commands/webstorm.md`

- [ ] **Step 1: Create commands/webstorm.md**

```bash
mkdir -p commands
```

File content:

```markdown
---
name: webstorm
description: Scaffold a 3-prototype static website workspace with anti-AI-bias guardrails. Asks structured questions, ingests brand assets, fetches UX references, and optionally dispatches 3 parallel build agents in isolated worktrees.
argument-hint: [--brief | --resume <path> | --rebuild style-N | --dry-run | --reconfigure]
---

Use the webstorm skill to scaffold a new 3-prototype web design project.

Arguments: $ARGUMENTS
```

- [ ] **Step 2: Verify the command will trigger the skill**

The command body says "Use the webstorm skill" — this causes Claude to invoke the `Skill` tool with `skill: "webstorm"`, loading `skills/webstorm/SKILL.md`. No further wiring needed.

- [ ] **Step 3: Commit**

```bash
git add commands/webstorm.md
git commit -m "feat: /webstorm slash command"
```

---

## Task 3: Anti-AI rules reference

**Files:**
- Create: `skills/webstorm/anti-ai-rules.md`

This file is read by the skill body and embedded verbatim in `CLAUDE.prototype.md.tmpl`. Write it once here; reference it elsewhere.

- [ ] **Step 1: Create skills/webstorm/anti-ai-rules.md**

```bash
mkdir -p skills/webstorm
```

File content:

```markdown
# Anti-AI-Slop Rules — Seven Measures

These measures are enforced at scaffold time (baked into per-prototype CLAUDE.md files)
and validated at build time (sniff-test.sh). All seven apply to every /webstorm project.

---

## Measure 1 — Mandatory concrete references

Phase 4 reference inputs are validated by `tests/reference-validator.sh`.

**Rejected:** single-word vague adjectives — `modern`, `clean`, `minimal`, `minimalist`,
`sleek`, `professional`, `elegant`, `simple`, `sophisticated`, `premium`, `luxury`,
`fresh`, `bold`, `dynamic`, `innovative`, `creative`, `unique`.

**Accepted:** URLs, named brands, named designers/studios, named typefaces,
named art movements (Bauhaus, Brutalism, Swiss design, De Stijl),
named eras (`90s magazine`, `early web`, `80s brutalist`).

Minimum 2 accepted references per prototype. The prompt re-asks on rejection.

---

## Measure 2 — Forbidden defaults in every prototype CLAUDE.md

Written verbatim into `CLAUDE.prototype.md.tmpl`. The builder reads CLAUDE.md as
scripture before writing a single line of markup.

### Typography
- No `Inter`, `system-ui`, or `-apple-system` as the primary typeface.
- Required: each prototype declares a named, character-ful typeface in `style-N/tokens.css`.

### Color
- No Tailwind default color scales (`slate-*`, `zinc-*`, `gray-*`, `indigo-*`,
  `purple-*`, `violet-*`) used as the brand color.
- No purple-to-blue, pink-to-orange, or teal-to-pink gradients.
- All hex values must trace to `brand/tokens.css` or a documented reference choice.

### Composition
- No centered-hero-with-headline-subtitle-two-CTAs as the default layout
  unless a named reference explicitly uses this pattern.
- No `rounded-2xl shadow-lg` card pattern as the default component.
- No three-column feature grid as the default below-hero section.

### Iconography
- No Lucide, Heroicons, or Font Awesome by default.
- Declare the icon strategy (custom SVG, dingbats, or none) in CLAUDE.md.

### Copy
- No "Transform your...", "Built for...", "The future of...", "Empower your..."
- Copy must derive from `brand/voice.md` or be lifted in tone from declared references.

---

## Measure 3 — frontend-design skill invocation (soft dependency)

Each builder dispatch prompt instructs: "Before writing any markup, invoke the
`frontend-design:frontend-design` skill if it is available in your session."

Falls back gracefully — if the skill is not installed, Measure 2 (prohibition list)
is the sole anti-slop mechanism. This is still sufficient.

---

## Measure 4 — Compositional commandment per prototype

Each prototype's CLAUDE.md contains one non-negotiable layout law. Chosen in Phase 4.

Available commandments (user may also write a custom one):
- **Editorial magazine grid** — left-aligned, ragged-right layout; no centered text blocks;
  no symmetric three-column grids.
- **Brutalist single-column** — hard horizontal rules between sections; monospace or
  condensed headlines; no gradients; high-contrast only.
- **Info-dense lock-up** — Bloomberg/FT density; tabular data welcome; tight line-height;
  small type; no hero images.
- **Asymmetric collage** — overlapping elements; varied column widths; no section
  uniformity; type at multiple scales on the same screen.
- **Centered classical** — if chosen, must compensate with unusual type or color treatment;
  this is the only commandment that permits a centered hero.
- **Swiss-grid functional** — strict grid adherence; geometric type; flat color fields;
  no drop shadows; no rounded corners.
- **Cinematic full-bleed** — large imagery or color fields dominate; type as counter-element;
  minimal UI chrome; scroll as cinematic progression.

---

## Measure 5 — AI-tell sniff test (automated)

After build, `tests/sniff-test.sh <style-N-dir>` scans for known AI tells.
In autonomous dispatch mode, HIGH findings trigger a builder re-dispatch (max 3 loops).
In checkpoint mode, the report is surfaced to the user for decision.

Sniff test detects:
- HIGH: Inter/system-ui as primary typeface, Tailwind default color classes as brand,
  purple-to-blue/pink-orange gradients, `rounded-2xl shadow-lg` combo, Lucide/Heroicons
  links, forbidden copy patterns.
- MEDIUM: centered hero heuristic (text-center in header/hero area).

---

## Measure 6 — Temperature → stricter anti-defaults, not looser

Temperature (0–100) is a visual boldness dial. Higher = more deviation from defaults,
not more freedom to hallucinate. The per-prototype directive:

| Temperature | CLAUDE.md directive |
|-------------|---------------------|
| 0–25  | "Stay close to safe corporate norms. Brand-conservative. No surprises." |
| 26–45 | "Confident but restrained. Avoid clichés but do not intentionally surprise." |
| 46–65 | "Distinctive. Make at least 2 unconventional compositional choices. Document them." |
| 66–85 | "Bold. Push type scale, layout asymmetry, and color use aggressively. Justify each choice." |
| 86–100 | "Experimental. Reject any default. If a section looks like 100 other websites, redo it. Every section must feel authored, not assembled." |

---

## Measure 7 — Design tokens before markup

The builder's CLAUDE.md states: write `style-N/tokens.css` BEFORE any HTML.
Derive from `brand/tokens.css` (locked floor) + commandment + temperature.
Markup work is blocked until tokens.css exists and is committed.

This forces the builder to make hard aesthetic decisions up front instead of
reaching for defaults mid-build. It also provides a one-file comparison surface
across prototypes.
```

- [ ] **Step 2: Commit**

```bash
git add skills/webstorm/anti-ai-rules.md
git commit -m "feat: anti-AI-slop rules reference"
```

---

## Task 4: Questions reference

**Files:**
- Create: `skills/webstorm/questions.md`

- [ ] **Step 1: Create skills/webstorm/questions.md**

```markdown
# Webstorm Questionnaire — All Phases

Used by SKILL.md as a reference for building AskUserQuestion calls.
The skill reads this file and adapts prompts from it.

---

## Phase 0 — Plugin settings (first run only)

**Q0a — Base path**
Question: "Where should /webstorm create new projects by default?"
Options: ~/Developer/, ~/Projects/, ~/Sites/, ~/Desktop/ [+ custom]
Saves to: .claude/webstorm.local.md → base_path

**Q0b — Date prefix**
Question: "Use YYMMDD date prefix in project folder names? (e.g. 260520_ClientName)"
Options: Yes (default) / No
Saves to: .claude/webstorm.local.md → default_date_prefix

**Q0c — Default dispatch mode**
Question: "Default behavior after scaffolding?"
Options:
- Scaffold only (prompt each time)
- Checkpoint dispatch (scaffold + build + review)
- Autonomous (scaffold + build + auto-fix, no interruptions)
Saves to: .claude/webstorm.local.md → default_dispatch_mode

---

## Phase 1 — Project basics

**Q1a — Project / client name**
Input: free text (used for folder naming and file headers)
Default: the cwd folder name if meaningful, else "Project"

**Q1b — Primary purpose**
Question: "What is the website's primary purpose?"
Options:
- Lead generation (capture inquiries, drive contact)
- E-commerce (sell products directly)
- Brand storytelling (shape perception, no direct CTA)
- Product showcase (demo what the product does)
- Service catalog (list offerings, drive bookings)
- Editorial / content (publish articles, attract readers)
- Portfolio (show work, attract clients or employers)
- Internal tool (restricted-access team resource)
[+ Custom]

**Q1c — Primary audience**
Question: "Who is the primary audience?"
Options:
- General consumers (B2C, wide age range)
- B2B decision-makers (procurement, leadership)
- Technical practitioners (developers, engineers, designers)
- Local community (geographic-specific, neighbourhood-scale)
- Investors / press (credibility-first audiences)
- Internal staff (employees, contractors)
[+ Custom]

**Q1d — Primary success metric**
Question: "What does success look like?"
Options:
- Form submissions (contact form, enquiry)
- Phone calls / WhatsApp clicks
- Bookings / appointments
- Online purchases / add-to-cart
- Newsletter signups
- Time on site / depth of scroll
- Brand impression (awareness, not measured)
[+ Custom]

---

## Phase 2 — Brand

**Q2a — Existing brand URL**
Question: "What is the client's website URL? (Paste URL or type 'none' if no website exists)"
Input: free text (URL or 'none')
If 'none': skip scrape, go to Q2c.

**Q2b — Local brand assets**
Question: "Do you have local brand files to provide? (logo, brand book PDF, palette swatches)"
Options: Yes / No
If yes: create project folder + assets/ immediately, print drop instruction, wait for 'continue'.

**Q2c — Voice and tone** (multi-select, max 3)
Question: "Pick up to 3 words that describe the brand's voice and tone."
Options:
- Authoritative (expert-led, decisive)
- Warm (approachable, human)
- Playful (light, wit-forward)
- Technical (precise, jargon-comfortable)
- Editorial (considered, narrative-led)
- Restrained (quiet confidence, no hard sell)
- Confident (direct, no apology)
- Cheeky (self-aware, a little irreverent)
[+ Custom]

---

## Phase 3 — Shared page architecture

**Q3a — Pages needed** (multi-select)
Question: "Which pages does this site need?"
Options:
- Home / Landing
- About / Team
- Services / Products overview
- Individual product / service detail
- Inventory / Catalog (browseable list)
- Pricing
- Contact
- Blog / News / Journal
- Case studies / Portfolio
- FAQ
[+ Custom]

**Q3b — Functional features** (multi-select)
Question: "Which features does the site need?"
Options:
- Contact form
- Booking / scheduler
- Inventory filter + search
- Image gallery / lightbox
- Video hero or background
- Map embed
- Newsletter signup
- Cookie consent banner
- Multi-language support
- Testimonials / reviews display
[+ Custom]

---

## Phase 4 — Per-prototype (4 batched prompts, each with 3 slots)

**Q4a — Compositional commandment** (one prompt, 3 slots — style-1, style-2, style-3)
Question: "Choose a compositional commandment for each prototype."
Options per slot:
- Editorial magazine grid (left-aligned, ragged-right, no centered text)
- Brutalist single-column (hard rules, monospace headlines, high contrast)
- Info-dense lock-up (Bloomberg/FT density, tabular, tight)
- Asymmetric collage (overlapping, varied scale, no section uniformity)
- Centered classical (symmetric, spacious — must compensate with bold type or color)
- Swiss-grid functional (strict grid, geometric, flat, no shadows or radii)
- Cinematic full-bleed (large imagery dominates, type as counter-element)
[+ Custom]

**Q4b — Visual boldness temperature** (one prompt, 3 slots)
Question: "Set visual boldness temperature (0–100) for each prototype."
Options per slot: 20 / 40 / 60 / 80 / 100 [+ Custom number]

**Q4c — References** (one prompt, 3 text inputs)
Question: "Provide at least 2 references per prototype (URLs, named brands, movements, eras).
Vague adjectives (modern, clean, minimal...) are rejected."
Input: free text per slot
Validated by: tests/reference-validator.sh

**Q4d — Off-limits** (one prompt, 3 optional text inputs)
Question: "Anything explicitly off-limits for each prototype? (optional)"
Examples: "no dark mode", "no carousels", "no stock photography"
Input: free text per slot (optional — leave blank to skip)

---

## Phase 5 — Tech and dispatch

**Q5a — Tailwind CDN**
Question: "Use Tailwind CSS via CDN? (No build step — just a <script> tag)"
Options:
- Yes, all prototypes use Tailwind CDN
- No, vanilla CSS only across all prototypes
- Per-prototype (I'll choose at build time)
Default: Yes

**Q5b — Dispatch mode**
Question: "After scaffolding, what should happen next?"
Options:
- Scaffold only — I'll build prototypes manually in separate sessions
- Build now (checkpoint) — dispatch 3 parallel agents, then review before continuing
- Build now (autonomous) — dispatch 3 parallel agents, auto-fix AI tells, finish without interruption
Default: from plugin settings (default_dispatch_mode)
```

- [ ] **Step 2: Commit**

```bash
git add skills/webstorm/questions.md
git commit -m "feat: questionnaire reference (all 5 phases)"
```

---

## Task 5: Sniff-test script and fixtures (TDD — write before templates)

**Files:**
- Create: `tests/run-all.sh`
- Create: `tests/sniff-test.sh`
- Create: `tests/fixtures/bad-prototype/index.html`
- Create: `tests/fixtures/bad-prototype/styles.css`
- Create: `tests/fixtures/good-prototype/index.html`
- Create: `tests/fixtures/good-prototype/styles.css`

- [ ] **Step 1: Create tests/sniff-test.sh**

```bash
mkdir -p tests/fixtures/bad-prototype tests/fixtures/good-prototype
```

```bash
#!/usr/bin/env bash
# Usage: bash tests/sniff-test.sh <prototype-dir>
# Returns: 0 if no HIGH findings, 1 if any HIGH findings
# Writes: <prototype-dir>/_ai-tells.md

set -euo pipefail

PROTO_DIR="${1:-}"
if [ -z "$PROTO_DIR" ] || [ ! -d "$PROTO_DIR" ]; then
  echo "Usage: bash tests/sniff-test.sh <prototype-dir>"
  exit 2
fi

REPORT_FILE="$PROTO_DIR/_ai-tells.md"
HIGH=0
MEDIUM=0
FINDINGS=()

check() {
  local severity="$1"
  local pattern="$2"
  local description="$3"
  local matches
  matches=$(grep -rn "$pattern" "$PROTO_DIR" \
    --include="*.html" --include="*.css" --include="*.js" 2>/dev/null \
    | grep -v "_ai-tells.md" || true)
  if [ -n "$matches" ]; then
    FINDINGS+=("[$severity] $description")
    while IFS= read -r line; do
      FINDINGS+=("  $line")
    done < <(echo "$matches" | head -3)
    FINDINGS+=("")
    if [ "$severity" = "HIGH" ]; then HIGH=$((HIGH+1)); else MEDIUM=$((MEDIUM+1)); fi
  fi
}

check "HIGH" "font-family:.*Inter"               "Forbidden typeface: Inter"
check "HIGH" "font-family:.*system-ui"            "Forbidden fallback-as-primary: system-ui"
check "HIGH" "\-apple\-system"                    "Forbidden fallback-as-primary: -apple-system"
check "HIGH" "class=\"[^\"]*slate-[0-9]"          "Forbidden Tailwind color: slate-*"
check "HIGH" "class=\"[^\"]*zinc-[0-9]"           "Forbidden Tailwind color: zinc-*"
check "HIGH" "class=\"[^\"]*indigo-[0-9]"         "Forbidden Tailwind color: indigo-*"
check "HIGH" "class=\"[^\"]*purple-[0-9]"         "Forbidden Tailwind color: purple-*"
check "HIGH" "class=\"[^\"]*violet-[0-9]"         "Forbidden Tailwind color: violet-*"
check "HIGH" "from-purple"                        "Forbidden gradient: purple-*"
check "HIGH" "from-pink"                          "Forbidden gradient: pink-*"
check "HIGH" "rounded-2xl.*shadow-lg\|shadow-lg.*rounded-2xl" "Forbidden card pattern"
check "HIGH" "lucide"                             "Forbidden icon library: Lucide"
check "HIGH" "heroicons"                          "Forbidden icon library: Heroicons"
check "HIGH" "font-awesome"                       "Forbidden icon library: Font Awesome"
check "HIGH" "Transform your"                     "Forbidden copy: 'Transform your...'"
check "HIGH" "Built for "                         "Forbidden copy: 'Built for...'"
check "HIGH" "The future of"                      "Forbidden copy: 'The future of...'"
check "HIGH" "Empower your"                       "Forbidden copy: 'Empower your...'"

HERO_HTML=$(grep -n "hero\|<header" "$PROTO_DIR"/*.html 2>/dev/null || true)
if echo "$HERO_HTML" | grep -q "text-center"; then
  FINDINGS+=("[MEDIUM] Centered hero detected — verify this matches the compositional commandment.")
  FINDINGS+=("")
  MEDIUM=$((MEDIUM+1))
fi

{
  echo "# AI-Tell Sniff Test"
  echo ""
  echo "**Prototype:** \`$PROTO_DIR\`  **Date:** $(date +%Y-%m-%d)"
  echo "**HIGH:** $HIGH  **MEDIUM:** $MEDIUM"
  echo ""
  if [ "${#FINDINGS[@]}" -eq 0 ]; then
    echo "✓ No AI-tell patterns detected."
  else
    echo "## Findings"
    echo ""
    for line in "${FINDINGS[@]}"; do echo "$line"; done
  fi
} > "$REPORT_FILE"

echo "Report → $REPORT_FILE  |  HIGH: $HIGH  MEDIUM: $MEDIUM"
[ "$HIGH" -eq 0 ]
```

```bash
chmod +x tests/sniff-test.sh
```

- [ ] **Step 2: Create bad-prototype fixture (should fail)**

`tests/fixtures/bad-prototype/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Bad Prototype</title>
  <link rel="stylesheet" href="https://unpkg.com/lucide-icons/dist/lucide.css">
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <header class="text-center py-20">
    <h1 class="text-slate-900 text-5xl font-bold">Transform your workflow</h1>
    <p class="text-zinc-500 mt-4">Built for modern teams who move fast.</p>
    <a class="bg-indigo-600 text-white px-6 py-3 rounded-2xl shadow-lg" href="#">Get started</a>
    <a class="border border-slate-300 px-6 py-3 rounded-2xl" href="#">Learn more</a>
  </header>
</body>
</html>
```

`tests/fixtures/bad-prototype/styles.css`:

```css
body {
  font-family: Inter, system-ui, -apple-system, sans-serif;
  background: linear-gradient(135deg, from-purple, to-blue);
}
```

- [ ] **Step 3: Create good-prototype fixture (should pass)**

`tests/fixtures/good-prototype/index.html`:

```html
<!DOCTYPE html>
<html lang="de">
<head>
  <title>Gutes Prototype</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <header class="site-header">
    <div class="masthead">
      <span class="issue-label">Kollektion 2026 — Ausgabe 1</span>
      <h1 class="display-headline">Fahrzeuge mit Geschichte</h1>
    </div>
    <nav class="horizontal-nav">
      <a href="/inventar">Inventar</a>
      <a href="/ankauf">Ankauf</a>
      <a href="/kontakt">Kontakt</a>
    </nav>
  </header>
  <main class="editorial-grid">
    <article class="featured-vehicle">
      <h2>BMW 3er — 1998</h2>
      <p>Originallackierung. Scheckheft lückenlos. Keine Vorschäden.</p>
    </article>
  </main>
</body>
</html>
```

`tests/fixtures/good-prototype/styles.css`:

```css
:root {
  --color-ink:      #1a1a18;
  --color-paper:    #f5f2ec;
  --color-accent:   #c9401a;
  --type-display:   'Editorial New', Georgia, serif;
  --type-body:      'GT America', Helvetica, sans-serif;
}

body {
  font-family: var(--type-body);
  background-color: var(--color-paper);
  color: var(--color-ink);
  margin: 0;
}

.display-headline {
  font-family: var(--type-display);
  font-size: clamp(2rem, 6vw, 5rem);
  line-height: 1.05;
  font-weight: 400;
}
```

- [ ] **Step 4: Run sniff test on bad fixture — expect FAIL**

```bash
bash tests/sniff-test.sh tests/fixtures/bad-prototype && echo "ERROR: should have failed" && exit 1 || echo "PASS: sniff-test correctly rejected bad prototype"
```

Expected output: `PASS: sniff-test correctly rejected bad prototype` (non-zero exit from sniff-test is expected).

- [ ] **Step 5: Run sniff test on good fixture — expect PASS**

```bash
bash tests/sniff-test.sh tests/fixtures/good-prototype && echo "PASS: sniff-test passed clean prototype" || echo "ERROR: clean prototype should not fail"
```

Expected output: `PASS: sniff-test passed clean prototype`

- [ ] **Step 6: Create tests/run-all.sh (scaffold — will grow in Task 6 and 8)**

```bash
#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

run_test() {
  local name="$1"
  local cmd="$2"
  echo ""
  echo "=== $name ==="
  if bash -c "$cmd"; then
    echo "PASS: $name"
    PASS=$((PASS+1))
  else
    echo "FAIL: $name"
    FAIL=$((FAIL+1))
  fi
}

run_test "sniff-test: detects AI tells" \
  "bash '$TESTS_DIR/sniff-test.sh' '$TESTS_DIR/fixtures/bad-prototype' && exit 1 || exit 0"

run_test "sniff-test: passes clean prototype" \
  "bash '$TESTS_DIR/sniff-test.sh' '$TESTS_DIR/fixtures/good-prototype'"

echo ""
echo "=========================="
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

```bash
chmod +x tests/run-all.sh
```

- [ ] **Step 7: Run full suite — expect both tests to pass**

```bash
bash tests/run-all.sh
```

Expected: `Results: 2 passed, 0 failed`

- [ ] **Step 8: Commit**

```bash
git add tests/
git commit -m "feat: sniff-test script + bad/good fixtures + run-all scaffold"
```

---

## Task 6: Reference validator and fixtures

**Files:**
- Create: `tests/reference-validator.sh`

- [ ] **Step 1: Create tests/reference-validator.sh**

```bash
#!/usr/bin/env bash
# Usage: bash tests/reference-validator.sh "Stripe, https://bloomberg.com, Bauhaus, modern"
# Returns: 0 if all accepted, 1 if any rejected

set -euo pipefail

INPUT="${1:-}"
if [ -z "$INPUT" ]; then
  echo "Usage: bash tests/reference-validator.sh \"ref1, ref2, ...\""
  exit 2
fi

REJECT_LIST=(
  "modern" "clean" "minimal" "minimalist" "sleek" "professional"
  "elegant" "simple" "sophisticated" "premium" "luxury" "fresh"
  "bold" "dynamic" "innovative" "creative" "unique" "stylish"
)

ACCEPTED=0
REJECTED=0

IFS=',' read -ra REFS <<< "$INPUT"
for ref in "${REFS[@]}"; do
  ref=$(echo "$ref" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$ref" ] && continue

  REJECT=false
  REJECT_REASON=""

  ref_lower=$(echo "$ref" | tr '[:upper:]' '[:lower:]')
  for adj in "${REJECT_LIST[@]}"; do
    if [ "$ref_lower" = "$adj" ]; then
      REJECT=true
      REJECT_REASON="Vague adjective. Use a URL, named brand, named designer, typeface, movement, or era."
      break
    fi
  done

  if [ "$REJECT" = "false" ]; then
    word_count=$(echo "$ref" | wc -w | tr -d ' ')
    if [ "$word_count" -eq 1 ] && ! echo "$ref" | grep -qE "^https?://"; then
      char_count=${#ref}
      if [ "$char_count" -lt 7 ] && ! echo "$ref" | grep -qE "[A-Z0-9]"; then
        REJECT=true
        REJECT_REASON="Single short lowercase word '$ref' looks like an adjective. Provide a proper name, URL, movement, or era."
      fi
    fi
  fi

  if [ "$REJECT" = "true" ]; then
    echo "REJECTED: \"$ref\" — $REJECT_REASON"
    REJECTED=$((REJECTED+1))
  else
    echo "ACCEPTED: \"$ref\""
    ACCEPTED=$((ACCEPTED+1))
  fi
done

echo ""
echo "Summary: $ACCEPTED accepted, $REJECTED rejected"
[ "$REJECTED" -eq 0 ]
```

```bash
chmod +x tests/reference-validator.sh
```

- [ ] **Step 2: Test with invalid inputs — expect FAIL (exit 1)**

```bash
bash tests/reference-validator.sh "modern, clean, minimal" && echo "ERROR: should fail" || echo "PASS: validator correctly rejected adjectives"
```

Expected: `REJECTED: "modern"`, `REJECTED: "clean"`, `REJECTED: "minimal"`, then `PASS: validator correctly rejected adjectives`.

- [ ] **Step 3: Test with valid inputs — expect PASS**

```bash
bash tests/reference-validator.sh "https://stripe.com, Bauhaus, Bloomberg, 90s magazine, GT America, Massimo Vignelli"
```

Expected: all `ACCEPTED`, exit 0.

- [ ] **Step 4: Add reference-validator tests to run-all.sh**

Edit `tests/run-all.sh` — add these two tests after the sniff-test block, before the final results lines:

```bash
run_test "reference-validator: rejects adjectives" \
  "bash '$TESTS_DIR/reference-validator.sh' 'modern, clean' && exit 1 || exit 0"

run_test "reference-validator: accepts URLs and brands" \
  "bash '$TESTS_DIR/reference-validator.sh' 'https://stripe.com, Bauhaus, Bloomberg, 90s magazine'"
```

- [ ] **Step 5: Run full suite — expect 4 tests pass**

```bash
bash tests/run-all.sh
```

Expected: `Results: 4 passed, 0 failed`

- [ ] **Step 6: Commit**

```bash
git add tests/reference-validator.sh tests/run-all.sh
git commit -m "feat: reference-validator script + tests"
```

---

## Task 7: Scaffold templates

**Files:**
- Create: `skills/webstorm/templates/scaffold.md.tmpl`
- Create: `skills/webstorm/templates/workflow.md.tmpl`
- Create: `skills/webstorm/templates/CLAUDE.root.md.tmpl`
- Create: `skills/webstorm/templates/CLAUDE.prototype.md.tmpl`
- Create: `skills/webstorm/templates/tokens.css.tmpl`
- Create: `skills/webstorm/templates/.gitignore.tmpl`

- [ ] **Step 1: Create scaffold.md.tmpl**

```bash
mkdir -p skills/webstorm/templates
```

```markdown
# {{project_name}} — Project Scaffold

## Goal

Build and compare three distinct web design prototypes for {{project_name}} in the same
repository. Each prototype evolves its own layout, interaction model, and visual language.

## Purpose

{{purpose}}

## Audience

{{audience}}

## Success metric

{{success_metric}}

## Pages

{{pages}}

## Functional features

{{features}}

## Tech stack

{{tech_stack}}

## Requirements

- Static HTML/CSS/JS delivery by default. No build step unless a prototype explicitly adds one.
- Each prototype is independently runnable (open index.html in a browser or run http.server).
- Each prototype has its own `CLAUDE.md` (local rules). Root CLAUDE.md is shared governance.
- Navigation, assets, and page relationships resolve within the active prototype folder.

## No-gos

- No forced shared page layout across all prototypes.
- No prototype-to-prototype inheritance for markup or styling.
- No coupling a prototype to another prototype's structure.
- No hidden cross-folder dependencies.

## Shared context

- Brand identity, content, and business purpose are shared (see `brand/`).
- Implementation decisions and page architecture remain prototype-local.
- Shared files cover only universally reused infrastructure, not visible UI design.
```

- [ ] **Step 2: Create workflow.md.tmpl**

```markdown
# {{project_name}} — Prototype Workflow

## Folder model

- `style-1/` — prototype 1 (standalone peer)
- `style-2/` — prototype 2 (standalone peer)
- `style-3/` — prototype 3 (standalone peer)
- Root docs define the shared project system.
- Each prototype defines only its own rules and decisions.

## Operating order

1. Read `scaffold.md` for the project brief and requirements.
2. Read `webstorm-brief.md` for full questionnaire output including brand and references.
3. Read the target prototype's `CLAUDE.md` for its local rules — this is scripture.
4. Make changes only inside the active prototype unless the task explicitly spans root governance.
5. Define decisions in CLAUDE.md before implementing them in markup.

## Worktree approach

When parallel build is active, three worktrees run alongside this root:

  `../<project>-style-1/`  (branch: proto/style-1)
  `../<project>-style-2/`  (branch: proto/style-2)
  `../<project>-style-3/`  (branch: proto/style-3)

Each builder writes only inside its own `style-N/` folder.
The other two folders are read-only context in every worktree.

## Cross-prototype isolation rules

- Do not copy structural assumptions from one prototype to another.
- Do not import layout decisions from sibling prototypes.
- Do not treat `style-1/` as a parent or source prototype.
- Shared context: business goals, brand floor, root governance only.
- Treat each prototype as a standalone website that happens to share a repo.

## Build order inside a prototype

1. Read root CLAUDE.md + this prototype's CLAUDE.md.
2. Write `style-N/tokens.css` (design tokens before markup — non-negotiable).
3. Commit tokens.css.
4. Build pages and styles.
5. Run `bash tests/sniff-test.sh style-N/`.
6. Fix any HIGH findings.
7. Commit final state.

## Preview

```bash
cd ../<project>-style-1 && python3 -m http.server 8001
cd ../<project>-style-2 && python3 -m http.server 8002
cd ../<project>-style-3 && python3 -m http.server 8003
```

Or open `style-N/index.html` directly in a browser.
```

- [ ] **Step 3: Create CLAUDE.root.md.tmpl**

```markdown
# {{project_name}} — Root Governance

This file applies to every prototype. Each prototype's own `CLAUDE.md` may add
additional rules but may not override the brand floor or the prohibition list below.

## Brand floor (non-negotiable)

`brand/tokens.css` — CSS custom properties that are the brand's visual floor.
Every prototype must consume these via `var(--brand-*)`. Do not redefine or
override brand token names.

`brand/voice.md` — tone and copy direction. Apply to all prototypes.

`assets/` — root-level brand files (logo, brand book, etc.). Use but do not modify.

## Shared pages

{{pages}}

## Shared features

{{features}}

## Anti-AI-slop prohibition list (all prototypes — no exceptions without documentation)

### Typography
- No `Inter`, `system-ui`, or `-apple-system` as the primary typeface.
- Required: each prototype declares a named typeface in `style-N/tokens.css`.

### Color
- No Tailwind default color scales (`slate-*`, `zinc-*`, `gray-*`, `indigo-*`,
  `purple-*`, `violet-*`) as the brand color.
- No purple-to-blue, pink-to-orange, or teal-to-pink gradients.
- All hex values must trace to `brand/tokens.css` OR a documented reference choice.

### Composition
- No centered-hero-plus-two-CTAs as the default layout unless a named reference uses it.
- No `rounded-2xl shadow-lg` card pattern as the default component.
- No three-column feature grid as the default below-hero section.

### Iconography
- No Lucide, Heroicons, or Font Awesome by default.
- Declare your icon strategy (custom SVG, dingbats, or none) in your `CLAUDE.md`.

### Copy
- No "Transform your...", "Built for...", "The future of...", "Empower your..."
- Copy must derive from `brand/voice.md` or be lifted in tone from your declared references.

### Deviation protocol
Any deviation from the above must be documented inline:
```html
<!-- deviation: centered hero — matches reference https://example.com where this pattern is intentional -->
```

## Worktree model

Each parallel agent writes only inside its own `style-N/` folder.
The other two style folders are read-only context.
```

- [ ] **Step 4: Create CLAUDE.prototype.md.tmpl**

This template is rendered 3 times (once per prototype) with n=1/2/3.

```markdown
# {{project_name}} / style-{{n}} — Prototype Rules

> This file is scripture for the style-{{n}} builder.
> Read it completely before writing a single line of markup.

## Compositional commandment

{{commandment}}

This is non-negotiable. Violate it only if the commandment makes a section
impossible to complete — document the reason inline.

## Visual boldness temperature: {{temperature}}/100

{{temperature_directive}}

## References — UX and conceptual only

{{references_list}}

For each reference, study:
- Information architecture (section ordering, content hierarchy)
- Interaction patterns (navigation model, scroll behaviour, disclosure)
- Layout grammar (grid logic, asymmetry, column relationships)
- Content rhythm (copy length, headline pacing, whitespace)
- Narrative pacing (how the product/service is introduced)

Do NOT borrow: colors, typefaces, brand-specific motifs, logos.
Those come from `brand/tokens.css` and `brand/voice.md`.

Extracted patterns: `references/style-{{n}}/`

## Off-limits

{{off_limits}}

## Forbidden defaults (in addition to root CLAUDE.md prohibitions)

Any deviation from the root prohibition list must be:
1. Referenced to a named source in your references list.
2. Documented inline: `/* deviation: reason */` or `<!-- deviation: reason -->`.

## Build checklist (complete in order — do not skip steps)

- [ ] Read root CLAUDE.md and this file completely.
- [ ] Read all files in `references/style-{{n}}/`.
- [ ] Invoke `frontend-design:frontend-design` skill if available in this session.
- [ ] Write `style-{{n}}/tokens.css` derived from `brand/tokens.css` + commandment + temperature.
      Do NOT write HTML before this file is committed.
- [ ] Build `style-{{n}}/index.html` and other pages per `webstorm-brief.md`.
- [ ] Write `style-{{n}}/styles.css` using only tokens from `style-{{n}}/tokens.css`
      and `brand/tokens.css`. No hardcoded hex values.
- [ ] Write `style-{{n}}/main.js` for declared features only — no extra functionality.
- [ ] Run `bash tests/sniff-test.sh style-{{n}}/`. Fix all HIGH findings before committing.
- [ ] Commit on branch `proto/style-{{n}}` with message "first-pass style-{{n}}".
```

- [ ] **Step 5: Create tokens.css.tmpl**

```css
/* {{project_name}} — Brand Design Tokens
 *
 * Source: {{tokens_source}}
 *
 * These are the brand floor. Prototypes extend via their own style-N/tokens.css
 * using these as the base. Do not override these property names.
 *
 * Greenfield note: if marked DRAFT, replace these with the real brand before production.
 */

:root {
  /* Brand colors */
  --brand-color-primary:    {{brand_color_primary}};
  --brand-color-secondary:  {{brand_color_secondary}};
  --brand-color-accent:     {{brand_color_accent}};
  --brand-color-neutral:    {{brand_color_neutral}};
  --brand-color-bg:         {{brand_color_bg}};
  --brand-color-surface:    {{brand_color_surface}};
  --brand-color-text:       {{brand_color_text}};
  --brand-color-text-muted: {{brand_color_text_muted}};

  /* Brand typography */
  --brand-type-display: {{brand_type_display}};
  --brand-type-body:    {{brand_type_body}};
  --brand-type-mono:    {{brand_type_mono}};

  /* Brand spacing (base rhythm — prototypes may extend) */
  --brand-space-xs:   0.25rem;
  --brand-space-sm:   0.5rem;
  --brand-space-md:   1rem;
  --brand-space-lg:   2rem;
  --brand-space-xl:   4rem;
  --brand-space-2xl:  8rem;

  /* Brand shape */
  --brand-radius-sm: {{brand_radius_sm}};
  --brand-radius-md: {{brand_radius_md}};
  --brand-radius-lg: {{brand_radius_lg}};
}
```

- [ ] **Step 6: Create .gitignore.tmpl**

```
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp
*.swo
*.sublime-workspace

# Sniff test reports (optional to ignore — remove this line to commit reports)
*/_ai-tells.md

# Local only
*.local

# Node (if accidentally introduced)
node_modules/
package-lock.json
```

- [ ] **Step 7: Commit all templates**

```bash
git add skills/webstorm/templates/
git commit -m "feat: scaffold templates (all 6)"
```

---

## Task 8: Template rendering test + golden output + sample brief

**Files:**
- Create: `tests/template-rendering.sh`
- Create: `tests/fixtures/sample-brief.md`
- Create: `tests/golden/scaffold.md`
- Create: `tests/golden/workflow.md`
- Create: `tests/golden/CLAUDE.md`
- Create: `tests/golden/tokens.css`
- Create: `tests/golden/.gitignore`

- [ ] **Step 1: Create tests/fixtures/sample-brief.md**

```markdown
---
project_name: Muster Projekt
purpose: Lead generation for a boutique architecture studio
audience: B2B decision-makers
success_metric: Form submissions
pages: Home, About, Projects, Contact
features: Contact form, Image gallery
tech_stack: Vanilla HTML/CSS/JS
tokens_source: Brand URL scrape (https://example-studio.ch)
brand_color_primary: #1a1a18
brand_color_secondary: #f5f2ec
brand_color_accent: #c9401a
brand_color_neutral: #888884
brand_color_bg: #f5f2ec
brand_color_surface: #ffffff
brand_color_text: #1a1a18
brand_color_text_muted: #888884
brand_type_display: 'Editorial New', Georgia, serif
brand_type_body: 'GT America', Helvetica, sans-serif
brand_type_mono: 'JetBrains Mono', monospace
brand_radius_sm: 0
brand_radius_md: 2px
brand_radius_lg: 4px
---
```

- [ ] **Step 2: Create tests/template-rendering.sh**

```bash
#!/usr/bin/env bash
# Usage: bash tests/template-rendering.sh <brief.md> <output-dir>

set -euo pipefail

BRIEF="${1:-}"
OUTPUT_DIR="${2:-}"
TEMPLATES_DIR="$(dirname "$0")/../skills/webstorm/templates"
GOLDEN_DIR="$(dirname "$0")/golden"

if [ -z "$BRIEF" ] || [ ! -f "$BRIEF" ]; then
  echo "Usage: bash tests/template-rendering.sh <brief.md> <output-dir>"
  exit 2
fi

mkdir -p "$OUTPUT_DIR"

extract() {
  local key="$1"
  grep "^${key}:" "$BRIEF" 2>/dev/null | head -1 \
    | sed "s/^${key}: *//" | tr -d '"' || echo "MISSING_${key}"
}

render_template() {
  local tmpl="$1"
  local out="$2"
  sed \
    -e "s|{{project_name}}|$(extract project_name)|g" \
    -e "s|{{purpose}}|$(extract purpose)|g" \
    -e "s|{{audience}}|$(extract audience)|g" \
    -e "s|{{success_metric}}|$(extract success_metric)|g" \
    -e "s|{{pages}}|$(extract pages)|g" \
    -e "s|{{features}}|$(extract features)|g" \
    -e "s|{{tech_stack}}|$(extract tech_stack)|g" \
    -e "s|{{tokens_source}}|$(extract tokens_source)|g" \
    -e "s|{{brand_color_primary}}|$(extract brand_color_primary)|g" \
    -e "s|{{brand_color_secondary}}|$(extract brand_color_secondary)|g" \
    -e "s|{{brand_color_accent}}|$(extract brand_color_accent)|g" \
    -e "s|{{brand_color_neutral}}|$(extract brand_color_neutral)|g" \
    -e "s|{{brand_color_bg}}|$(extract brand_color_bg)|g" \
    -e "s|{{brand_color_surface}}|$(extract brand_color_surface)|g" \
    -e "s|{{brand_color_text}}|$(extract brand_color_text)|g" \
    -e "s|{{brand_color_text_muted}}|$(extract brand_color_text_muted)|g" \
    -e "s|{{brand_type_display}}|$(extract brand_type_display)|g" \
    -e "s|{{brand_type_body}}|$(extract brand_type_body)|g" \
    -e "s|{{brand_type_mono}}|$(extract brand_type_mono)|g" \
    -e "s|{{brand_radius_sm}}|$(extract brand_radius_sm)|g" \
    -e "s|{{brand_radius_md}}|$(extract brand_radius_md)|g" \
    -e "s|{{brand_radius_lg}}|$(extract brand_radius_lg)|g" \
    "$tmpl" > "$out"
}

render_template "$TEMPLATES_DIR/scaffold.md.tmpl"      "$OUTPUT_DIR/scaffold.md"
render_template "$TEMPLATES_DIR/workflow.md.tmpl"      "$OUTPUT_DIR/workflow.md"
render_template "$TEMPLATES_DIR/CLAUDE.root.md.tmpl"   "$OUTPUT_DIR/CLAUDE.md"
render_template "$TEMPLATES_DIR/tokens.css.tmpl"       "$OUTPUT_DIR/tokens.css"
cp "$TEMPLATES_DIR/.gitignore.tmpl" "$OUTPUT_DIR/.gitignore"

echo "Rendered to: $OUTPUT_DIR"

# Check for un-substituted placeholders
UNSUBSTITUTED=$(grep -r "{{" "$OUTPUT_DIR" 2>/dev/null || true)
if [ -n "$UNSUBSTITUTED" ]; then
  echo ""
  echo "ERROR: Un-substituted placeholders found:"
  echo "$UNSUBSTITUTED"
  exit 1
fi

# Compare against golden if it exists
if [ -d "$GOLDEN_DIR" ]; then
  DIFFS=0
  for f in scaffold.md workflow.md CLAUDE.md tokens.css .gitignore; do
    [ -f "$GOLDEN_DIR/$f" ] || continue
    if ! diff -q "$GOLDEN_DIR/$f" "$OUTPUT_DIR/$f" > /dev/null 2>&1; then
      echo "DIFF: $f"
      diff "$GOLDEN_DIR/$f" "$OUTPUT_DIR/$f" | head -20 || true
      DIFFS=$((DIFFS+1))
    fi
  done
  [ "$DIFFS" -eq 0 ] && echo "✓ Matches golden output."
  [ "$DIFFS" -gt 0 ] && exit 1
fi
```

```bash
chmod +x tests/template-rendering.sh
```

- [ ] **Step 3: Generate golden output from the sample brief**

```bash
bash tests/template-rendering.sh tests/fixtures/sample-brief.md tests/golden/
```

Verify the output looks correct by reading `tests/golden/scaffold.md`, `tests/golden/tokens.css`. If any file looks wrong, fix the template (Task 7) and regenerate. The golden files represent correct output — commit them once they look right.

- [ ] **Step 4: Add template-rendering test to run-all.sh**

Edit `tests/run-all.sh` — add before the final results lines:

```bash
run_test "template-rendering: no unsubstituted placeholders" \
  "bash '$TESTS_DIR/template-rendering.sh' \
     '$TESTS_DIR/fixtures/sample-brief.md' \
     '$TESTS_DIR/tmp-output'"
```

- [ ] **Step 5: Run full suite — expect 5 tests pass**

```bash
bash tests/run-all.sh
```

Expected: `Results: 5 passed, 0 failed`

- [ ] **Step 6: Commit**

```bash
git add tests/
git commit -m "feat: template-rendering test + sample brief + golden output"
```

---

## Task 9: Builder dispatch prompt

**Files:**
- Create: `skills/webstorm/dispatch/builder-prompt.md`

- [ ] **Step 1: Create skills/webstorm/dispatch/builder-prompt.md**

```bash
mkdir -p skills/webstorm/dispatch
```

```markdown
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
- Be independently browseable (all links resolve within style-{{n}}/)

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
- Temperatures honored (yes/no)
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/webstorm/dispatch/
git commit -m "feat: builder dispatch prompt template"
```

---

## Task 10: Main skill file (SKILL.md)

**Files:**
- Create: `skills/webstorm/SKILL.md`

This is the longest file. It is the skill body Claude reads when `/webstorm` is invoked.
It must be self-contained — Claude will not read any other file unless this one tells it to.

- [ ] **Step 1: Create skills/webstorm/SKILL.md**

```markdown
---
name: webstorm
description: Scaffold a 3-prototype static website workspace with brand ingestion, UX reference extraction, anti-AI-slop guardrails, and optional parallel build agents in isolated worktrees. Use when the user runs /webstorm or asks to scaffold a multi-prototype web design project.
---

# Webstorm Skill

You are the webstorm skill. Follow this checklist exactly. Use TodoWrite to track each step.

---

## How to read arguments

The user may have passed arguments via /webstorm:

- `--brief`        → skip wizard; write pre-filled webstorm-brief.md, instruct user to edit it, wait for 'continue'
- `--resume <path>` → load existing webstorm-brief.md at <path>, skip filled fields, continue from first empty one
- `--rebuild style-N` → re-dispatch builder for one prototype only (skip questionnaire)
- `--dry-run`      → run full wizard but print what would be written; do not create files
- `--reconfigure`  → re-run Phase 0 (plugin settings) only
- (no args)        → full wizard mode

---

## Phase 0 — Plugin settings

Read `.claude/webstorm.local.md` if it exists. If it does not exist (first run), run Q0.

**Q0 — First-run settings (only if .claude/webstorm.local.md is missing):**

Call AskUserQuestion with these three questions:

1. "Where should /webstorm create new projects by default?"
   Options: ~/Developer/ | ~/Projects/ | ~/Sites/ | ~/Desktop/

2. "Use YYMMDD date prefix in project folder names? (e.g. 260520_ClientSlug)"
   Options: Yes (recommended) | No

3. "Default dispatch mode after scaffolding?"
   Options: Scaffold only | Checkpoint dispatch (build + review) | Autonomous (build + auto-fix)

After answers, write `.claude/webstorm.local.md`:

```markdown
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

Call AskUserQuestion:

1. "Project / client name?" — free text. Default: current folder name.
2. "Primary purpose?" — options: Lead generation | E-commerce | Brand storytelling | Product showcase | Service catalog | Editorial / content | Portfolio | Internal tool
3. "Primary audience?" — options: General consumers | B2B decision-makers | Technical practitioners | Local community | Investors / press | Internal staff
4. "Primary success metric?" — options: Form submissions | Phone calls / WhatsApp | Bookings | Purchases | Newsletter signups | Time on site | Brand impression

Write answers to webstorm-brief.md (create file, YAML frontmatter).

---

## Phase 2 — Brand

Call AskUserQuestion:

1. "Client website URL? (paste URL or type 'none')" — free text
2. "Do you have local brand files to provide? (logo, brand book PDF, palette swatches)" — Yes | No
3. "Brand voice and tone (pick up to 3):" — Authoritative | Warm | Playful | Technical | Editorial | Restrained | Confident | Cheeky [multiSelect: true]

**If user provided a URL:**
- Use Firecrawl (mcp__plugin_context7_context7__query-docs or firecrawl skill) to scrape the URL.
- Extract: navigation structure (IA), content section ordering, interaction patterns, copy tone.
- Do NOT extract: colors, typefaces, or visual design tokens.
- Write findings to `brand/voice.md` as "IA observations from <url>".

**If user has local brand files (answer = Yes):**
- Determine base_path from plugin settings.
- Determine project name (YYMMDD_ClientSlug form if date prefix is on).
- Create project folder + `assets/` directory now (early creation for asset drop).
- Print: "Drop your brand files into `<full-path>/assets/` then reply `continue`."
- Wait for user to reply 'continue'.
- Scan `assets/`:
  - Files with 'logo' in name + .svg/.png/.jpg → record as logo; note dominant colors.
  - .pdf files → read as text; extract color mentions, typeface mentions, voice guidelines.
  - .ai / .psd / .fig → note as "design source, not parsed."
- Synthesize brand/tokens.css from scan findings.
- Synthesize brand/voice.md from scan findings + URL scrape (if both present, merge).

**If no URL and no local files (greenfield):**
- Generate a draft brand:
  - Pick a neutral typographic pairing (non-Inter, non-system-ui)
  - Pick a 6-color palette from the voice/tone choices
  - Write brand/tokens.css marked `/* DRAFT — replace before production */`
  - Write brand/voice.md with tone-derived copy direction

---

## Phase 3 — Shared page architecture

Call AskUserQuestion (multiSelect: true):

1. "Which pages does this site need?"
   Options: Home | About / Team | Services overview | Product / service detail | Inventory / Catalog | Pricing | Contact | Blog / News | Case studies | FAQ

2. "Which features does the site need?"
   Options: Contact form | Booking / scheduler | Inventory filter + search | Image gallery | Video hero | Map embed | Newsletter signup | Cookie consent | Multi-language | Testimonials

Write answers to webstorm-brief.md.

---

## Phase 4 — Per-prototype (4 batched 3-slot prompts)

For each of the 4 questions below, call AskUserQuestion ONCE with 3 sub-questions
(one per prototype slot) in the same tool call. This means Phase 4 is exactly 4 calls.

**Q4a — Compositional commandments (3 slots)**
Options per slot: Editorial magazine grid | Brutalist single-column | Info-dense lock-up | Asymmetric collage | Centered classical | Swiss-grid functional | Cinematic full-bleed

**Q4b — Visual boldness temperatures (3 slots)**
Options per slot: 20 | 40 | 60 | 80 | 100

**Q4c — References (3 text inputs)**
Note: minimum 2 references per prototype. Vague adjectives are rejected.
For any prototype that submits only adjectives, call `bash tests/reference-validator.sh "<refs>"`.
If rejected, ask again with the rejection reason shown.

**Q4d — Off-limits (3 optional text inputs)**
Optional. Examples: "no dark mode", "no carousels", "no stock photography".

Write all Phase 4 answers to webstorm-brief.md.

---

## Eager reference fetch

For each prototype's references:
- For each URL reference: use Firecrawl to scrape. Extract IA, interactions, layout grammar,
  content rhythm. Write to `references/style-N/<slug>.md`.
  Format: sections "## IA pattern", "## Interaction moves", "## Layout grammar",
  "## Content rhythm". NO "## Color" or "## Typography" sections.
- For brand/studio/designer name references: note in the reference file as a conceptual anchor
  with a one-paragraph description of their known IA/UX approach.
- For named art movements / eras: write a one-paragraph description of compositional
  and structural characteristics. No color or typeface descriptions.
- For references that fail to scrape: write `references/style-N/_fetch-errors.md` with
  the failed URL and reason. Ask user: retry / replace / skip.

---

## Phase 5 — Tech stack and dispatch

Call AskUserQuestion:

1. "Use Tailwind CSS via CDN (no build step, just a script tag)?"
   Options: Yes, all prototypes | No, vanilla CSS only | Per-prototype (I'll choose at build time)

2. "After scaffolding, what should happen?"
   Options: Scaffold only | Build now (checkpoint — review after first pass) | Build now (autonomous — auto-fix, no interruptions)

Write answers to webstorm-brief.md.

---

## Scaffold file generation

If `--dry-run`, print what would be written and exit.

Otherwise:

1. Determine project path: `<base_path>/<YYMMDD_ClientSlug>/<project-slug>/`
   (If project folder was already created in Phase 2 for asset drop, use that path.)

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

3. Render templates from `skills/webstorm/templates/` using values from webstorm-brief.md.
   Use `tests/template-rendering.sh webstorm-brief.md <project>/` for reproducible rendering.

4. Write `brand/tokens.css` and `brand/voice.md` (from Phase 2 ingestion or greenfield draft).

5. For each prototype (n = 1, 2, 3):
   Render `CLAUDE.prototype.md.tmpl` with:
   - n = prototype number
   - commandment = Phase 4 Q4a answer for this prototype
   - temperature = Phase 4 Q4b answer
   - temperature_directive = directive text from anti-ai-rules.md Measure 6 table
   - references_list = Phase 4 Q4c answer (validated)
   - off_limits = Phase 4 Q4d answer (or "None declared." if blank)
   Write to `style-N/CLAUDE.md`.

6. Self-check before committing:
   - Every `style-N/CLAUDE.md` contains the prohibition list? → confirm
   - `brand/tokens.css` exists and has no unfilled placeholders? → run `grep '{{' brand/tokens.css`
   - `references/style-N/` has at least one file per prototype? → confirm
   - `webstorm-brief.md` is complete (no empty required fields)? → confirm
   If any check fails, fix before committing.

7. `git init` inside the project folder.
   ```bash
   git init
   git add .
   git commit -m "scaffold from /webstorm — $(date +%Y-%m-%d)"
   ```

8. Print:
   ```
   ✓ Project scaffolded: <project-path>
   Preview:
     cd <project>-style-1 && python3 -m http.server 8001
     cd <project>-style-2 && python3 -m http.server 8002
     cd <project>-style-3 && python3 -m http.server 8003
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

2. Dispatch 3 Agent calls in ONE message (run concurrently):
   For each n in (1, 2, 3):
   - Read `skills/webstorm/dispatch/builder-prompt.md`
   - Interpolate: n, project_name, worktree_path (absolute), model (sonnet if temp<80, opus if temp≥80)
   - Call: Agent(description="Build style-N: <project_name>", prompt=<interpolated>, subagent_type="general-purpose", model=<model>)

3. Await all three returns.

4. Run sniff test on each prototype (3 parallel Agent calls):
   Agent(prompt="Run `bash tests/sniff-test.sh style-N/` in <worktree-path>. Return the contents of style-N/_ai-tells.md verbatim.")

5. Print summary:
   - Per prototype: file count, sniff-test severity (HIGH/MEDIUM/none), path
   - Invite user to review each prototype, then decide: accept / iterate / rebuild one

6. Exit.

### Autonomous dispatch

1–4. Same as Checkpoint.

5. For each prototype with HIGH sniff-test findings:
   - Re-dispatch builder with original prompt + appended section:
     "Your previous pass had these HIGH AI-tell findings:\n<findings>\nFix them without breaking the compositional commandment. Do not introduce new forbidden patterns."
   - Run sniff test again.
   - Repeat up to 3 total iterations per prototype.

6. Auto-commit final state on each worktree branch.

7. Print final summary and exit.

---

## Edge cases

- Re-invoked inside existing webstorm project (webstorm-brief.md found): offer resume / new / abort.
- All 3 builders flag same tell: surface as a brand-level issue; offer to revise brand/tokens.css.
- Builder times out or errors: flag that prototype, continue others, print rebuild command.
- Asset-drop 'continue' with empty assets/: warn + continue.
- Non-git cwd: create new git repo at project path; do not touch cwd.
- Project folder name collision: prompt for new name; never overwrite.
- frontend-design skill not installed: continue with prohibition list only; note in summary.
```

- [ ] **Step 2: Commit**

```bash
git add skills/webstorm/SKILL.md
git commit -m "feat: main webstorm skill body"
```

---

## Task 11: Version bump script and README

**Files:**
- Create: `scripts/bump-version.sh`
- Create: `README.md`

- [ ] **Step 1: Create scripts/bump-version.sh**

```bash
mkdir -p scripts
```

```bash
#!/usr/bin/env bash
# Usage: bash scripts/bump-version.sh [major|minor|patch]
# Default: patch bump

set -euo pipefail

PART="${1:-patch}"
CURRENT=$(grep '"version"' plugin.json | sed 's/.*"\([0-9.]*\)".*/\1/')
IFS='.' read -ra PARTS <<< "$CURRENT"

MAJOR="${PARTS[0]}"
MINOR="${PARTS[1]}"
PATCH="${PARTS[2]}"

case "$PART" in
  major) MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR+1)); PATCH=0 ;;
  patch) PATCH=$((PATCH+1)) ;;
  *) echo "Usage: bash scripts/bump-version.sh [major|minor|patch]"; exit 2 ;;
esac

NEW="$MAJOR.$MINOR.$PATCH"

# Update plugin.json
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" plugin.json

# Update README badge
sed -i '' "s/version-$CURRENT-/version-$NEW-/g" README.md 2>/dev/null || true

echo "Bumped: $CURRENT → $NEW"
git add plugin.json README.md
git commit -m "chore: bump version to $NEW"
```

```bash
chmod +x scripts/bump-version.sh
```

- [ ] **Step 2: Create README.md**

```markdown
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

Plugin settings live in `.claude/webstorm.local.md`:

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

Every push to `main` must bump the version. Without a bump, `/plugin` reports "already at latest"
and teammates' sessions don't pick up changes.

---

## License

MIT
```

- [ ] **Step 3: Commit**

```bash
git add scripts/bump-version.sh README.md
git commit -m "feat: bump-version script + README"
```

---

## Task 12: Run all tests and fix issues

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/leyra/Developer/03_AI_Agents/webstorm-plugin
bash tests/run-all.sh
```

Expected: `Results: 5 passed, 0 failed`

- [ ] **Step 2: If any test fails, diagnose and fix**

Sniff-test fails on bad-prototype: check `tests/fixtures/bad-prototype/_ai-tells.md` — the fixture must contain at least one of the grep patterns in sniff-test.sh.

Sniff-test fails on good-prototype: check `tests/fixtures/good-prototype/_ai-tells.md` — if a false positive, either remove the pattern from sniff-test.sh or fix the good fixture.

Reference validator fails: check `tests/reference-validator.sh` REJECT_LIST — ensure "modern" and "clean" are in it; ensure "Bauhaus" and "Bloomberg" pass (capital letters + multi-word bypass the heuristic).

Template rendering fails with unsubstituted placeholders: check `tests/fixtures/sample-brief.md` — ensure every key in the template has a matching key in the brief. Fix the template or the brief.

- [ ] **Step 3: Re-run until all 5 pass**

```bash
bash tests/run-all.sh
```

- [ ] **Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: test suite passes clean"
```

---

## Task 13: Bump to 0.1.0 and push

- [ ] **Step 1: Verify everything is committed**

```bash
git status
```

Expected: `nothing to commit, working tree clean`

- [ ] **Step 2: Verify final file structure**

```bash
find . -not -path './.git/*' -not -path './tests/tmp-output/*' | sort
```

Expected output should include all files from the File Map at the top of this plan.

- [ ] **Step 3: Run tests one final time**

```bash
bash tests/run-all.sh
```

Expected: `Results: 5 passed, 0 failed`

- [ ] **Step 4: Push to GitHub**

```bash
git push origin main
```

- [ ] **Step 5: Verify plugin installs cleanly (optional smoke test)**

In a separate Claude Code session:
```
/plugin marketplace add https://github.com/fernandoleyra/webstorm
/plugin install webstorm
```

Then type `/webstorm --dry-run` and confirm the wizard launches.

---

## Spec coverage check

| Spec section | Covered by |
|---|---|
| Plugin architecture | Task 1 (plugin.json, marketplace.json) |
| /webstorm command | Task 2 |
| 15-prompt wizard (5 phases) | Task 10 (SKILL.md phases 0-5) |
| Brand URL direct ask | Task 10 Phase 2 |
| Brand asset drop + scan | Task 10 Phase 2 |
| Greenfield brand generation | Task 10 Phase 2 |
| Eager reference fetch (UX only) | Task 10 reference fetch section |
| Phase 4 batched 3-slot prompts | Task 10 Phase 4 |
| Anti-AI rules (all 7 measures) | Task 3 (anti-ai-rules.md) + Task 7 (templates) |
| Prohibition list in CLAUDE.prototype | Task 7 (CLAUDE.prototype.md.tmpl) |
| Design tokens before markup | Task 9 (builder prompt Step 1) |
| Sniff-test script | Task 5 |
| Reference validator | Task 6 |
| Template rendering | Task 7 + Task 8 |
| Scaffold file generation | Task 10 (scaffold section) |
| Worktree creation (on demand) | Task 10 (dispatch section) |
| Parallel agent dispatch | Task 10 (checkpoint + autonomous) |
| Builder dispatch prompt | Task 9 |
| Plugin settings (.claude/webstorm.local.md) | Task 10 Phase 0 |
| Flow modes (brief / resume / rebuild / dry-run / reconfigure) | Task 10 (arguments section) |
| Edge cases | Task 10 (edge cases section) |
| Version bump script | Task 11 |
| README | Task 11 |
| Tests | Tasks 5, 6, 8, 12 |
