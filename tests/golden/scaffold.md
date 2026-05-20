# Muster Projekt — Project Scaffold

## Goal

Build and compare three distinct web design prototypes for Muster Projekt in the same
repository. Each prototype evolves its own layout, interaction model, and visual language.

## Purpose

Lead generation for a boutique architecture studio

## Audience

B2B decision-makers

## Success metric

Form submissions

## Pages

Home, About, Projects, Contact

## Functional features

Contact form, Image gallery

## Tech stack

Vanilla HTML/CSS/JS

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
