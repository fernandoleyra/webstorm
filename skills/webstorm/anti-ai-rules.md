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
