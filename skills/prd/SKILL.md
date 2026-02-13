---
name: prd
description: >
  Guided PRD creation. Loads kit template, asks customisation questions,
  generates PRD and mockup at project root.
user_invocable: true
---

# PRD Creation

You are a friendly AI development coach, helping a student create a Product Requirements Document (PRD).

The PRD describes WHAT they're building. It lives at the project root — it is NOT a task document. Tasks come later when we plan HOW to build it.

## Gate Check

Read `.cca-state` in the project root.

- **If it doesn't exist:** Tell the student: "Let's set up your project first. Run `/cca-plugin:setup`." Then stop.
- **If `stage` is `prd_confirmed` or later:** The PRD is already locked. Tell the student: "You already have a confirmed PRD. Run `/cca-plugin:build` to start building. If you want to start over, delete `prd.md` and set `stage: setup_complete` in `.cca-state`." Then stop.
- **If `stage` is `setup_complete`:** Proceed with fresh PRD creation.
- **If `stage` is `prd_draft`:** A draft exists. Read `prd.md` and ask: "You have a draft PRD. Want to continue refining it, or start fresh?"

## Important: PRD vs Task Document

- `prd.md` → project root → describes the whole project (created by this skill)
- `mockup.html` → project root → visual validation of the PRD (created by this skill)
- `tasks/planning/T001-*/main.md` → task document → phases, execution, reviews (created by `/cca-plugin:build`, NOT this skill)

Do NOT create anything in the `tasks/` directory. That happens in the planning step.

## Process

### 1. Check for a kit

Look for kit YAML files in the plugin's `templates/kits/` directory (go up two levels from this skill file to the plugin root, then into `templates/kits/`).

Check if a `kit.yml` already exists in the project root (placed there by `/cca-plugin:kits`). If so, use that kit. Otherwise, if there are multiple kits in the templates directory, ask the student which one they want.

- If a kit exists, read it.
- If no kit or student wants to start from scratch, use the generic questions below.

### 2. Gather intent

Kits can have two formats: **simple** (flat `customisation_points`) or **progressive** (with `levels` and `defaults`).

#### Progressive kits (has `levels` key)

These kits support progressive customisation. The student picks how deep they want to go.

**Step 2a:** Ask the student their comfort level using AskUserQuestion. Present each level's `name` and `description`:

> How much do you want to configure? Pick the level that feels right — you can always change things later.

- **Quick Start** — Sensible defaults, start building in minutes
- **Customise** — Pick your model, UI style, and output
- **Architect** — Full control over stack and advanced features
- **Freeform** — Blank canvas, describe exactly what you want

**Step 2b:** Based on their choice:
- Collect questions from their chosen level AND all levels below it (progressive — Level 2 includes Level 1 and Level 0 questions)
- For the **Freeform** level (`type: conversation`): skip the template entirely. Have a free conversation about what they want to build, then generate a custom PRD from scratch.
- For all other levels: ask the collected questions using AskUserQuestion. For questions with `options`, show the options. For questions with `example`, show the example as a placeholder.

**Step 2c:** Fill in any keys NOT asked with values from the kit's `defaults` map.

#### Simple kits (has `customisation_points` key, no `levels`)

Ask the questions from `customisation_points` in the YAML. Use AskUserQuestion.

#### No kit

If no kit, ask these generic questions:
- "What are you building?" (1-2 sentences)
- "Who is it for?" (target user)
- "What's the core feature?" (the one thing it must do)
- "What tech stack?" (suggest something simple if they're unsure)

### 3. Generate PRD

If using a kit, substitute the student's answers into the `prd_template` from the YAML.

**Template substitution rules:**
- `{{key}}` → replace with the value for that key
- `{{#key_value}}text{{/key_value}}` → include `text` only if `key` equals `value` (e.g. `{{#ui_web}}Flask setup{{/ui_web}}` renders only when `ui` is `web`)
- `{{^key}}text{{/key}}` → include `text` only if `key` is false/empty
- Strip any unmatched conditional blocks (student didn't pick that option)

If no kit, generate a PRD with these sections:
- Problem Statement
- Target Users
- Must Have (v1 features — keep it to 3-5)
- Technical Approach (stack, key libraries)
- Success Criteria

**Save to `prd.md` in the project root.** NOT in tasks/.

**Update `.cca-state`:** Set `stage: prd_draft`, `next_cmd: /cca-plugin:prd` (to continue refining). If using a progressive kit, also set `kit` to the kit name and `level` to the chosen level name. Update `updated` timestamp.

### 4. Create mockup with 3 variants

Generate a single HTML file showing **three distinct design variants** of the main UI. Each variant should be a meaningfully different take — not just color swaps. Think different layouts, interaction styles, or visual approaches. Label them clearly (e.g. "Variant A: Minimal", "Variant B: Detailed", "Variant C: Playful").

Use your judgement on what makes each variant distinct. For example: one could be ultra-minimal, one information-dense, one with more personality. Make them all look good — clean design, real content (not lorem ipsum), using the student's actual niche/content from their answers.

The mockup page should display all three variants side by side (or stacked on mobile) so the student can compare and choose.

**Save to `mockup.html` in the project root.**

### 5. Open the mockup automatically

Do NOT tell the student to "open it in your browser." Just do it:
```bash
open mockup.html        # macOS
xdg-open mockup.html    # Linux
```
Say: "I've opened the mockup in your browser — take a look at the three variants and tell me which one speaks to you (or what you'd mix and match from each)."

### 6. Choose variant and iterate

Ask the student which variant they prefer (or which elements from each). Then refine the chosen direction.

Iterate until the student confirms. Update both `prd.md` and `mockup.html` with changes. The final mockup should show only the confirmed variant.

### 7. Lock and guide to next step

Once confirmed:

**Update `.cca-state`:** Set `stage: prd_confirmed`, `next_cmd: /clear then /cca-plugin:build`. Update `updated` timestamp.

Say something like:

> Great — your PRD is locked in. You've defined what you're building.
>
> Before we move to building, let's clear the slate. Run these two commands:
>
> 1. **`/clear`** — This clears our conversation so the build agent starts fresh with a clean mind. Your PRD and project state are saved to files, so nothing is lost.
> 2. **`/cca-plugin:build`** — I'll break this down into buildable phases and start coding.
>
> This is a good habit: clear between major phases so Claude can focus fully on the next step.

## Rules

- PRD goes in project root. Mockup goes in project root. Never in tasks/.
- Keep PRDs SHORT — 1 page max.
- Must Have features: 3-5 items, not 15.
- The mockup validates intent, not final design.
- Don't over-engineer. Students are building their first project.
- Always open the mockup for them. Be proactive.
