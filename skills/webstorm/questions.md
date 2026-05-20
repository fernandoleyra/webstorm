# Webstorm Questionnaire — All Phases

Used by SKILL.md as a reference for building AskUserQuestion calls.
The skill reads this file and adapts prompts from it.

---

## Phase 0 — Plugin settings (first run only)

**Q0a — Base path**
Question: "Where should /webstorm create new projects by default?"
Options: ~/Developer/ | ~/Projects/ | ~/Sites/ | ~/Desktop/ [+ custom]
Saves to: .claude/webstorm.local.md → base_path

**Q0b — Date prefix**
Question: "Use YYMMDD date prefix in project folder names? (e.g. 260520_ClientSlug)"
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

**Q4b — Visual boldness temperatures** (one prompt, 3 slots)
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
Question: "After scaffolding, what should happen?"
Options:
- Scaffold only — I'll build prototypes manually in separate sessions
- Build now (checkpoint — review after first pass)
- Build now (autonomous — auto-fix, no interruptions)
Default: from plugin settings (default_dispatch_mode)
