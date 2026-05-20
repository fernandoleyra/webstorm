# Muster Projekt — Prototype Workflow

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
