# T001: Convert CCA to Operator Model

## Meta
- **Status:** COMPLETE
- **Created:** 2026-02-10
- **Last Updated:** 2026-02-11
- **Blocked Reason:** —

## Task

Convert CCA from an embedded model (where it bundles task-workflow templates internally) to an **operator model** (like lem-engine) that uses task-workflow as a shared engine. Students install both plugins via a single script. CCA owns the student experience (onboarding, kits, PRD, coaching); task-workflow owns the execution engine (agents, templates, state machine).

---

## Plan

### Objective

Decouple CCA from its embedded task-workflow templates so that CCA acts as a student-facing operator layer on top of the shared task-workflow engine, enabling both plugins to evolve independently while students get a single install experience.

### Scope
- **In:** Move CLAUDE.md template to task-workflow, strip CCA embedded templates, update all 3 existing skills (setup, kits, prd), create new `/cca-plugin:build` orchestrator skill, create install script, update plugin.json
- **Out:** Changes to task-workflow agent skills themselves (plan, execute, review-code, etc.), new kits, documentation site, CI/CD

### Phases

#### Phase 1: Move task procedures template to task-workflow
- **Objective:** Get the CCA-specific CLAUDE.md template into the task-workflow templates directory so it becomes the shared source of truth for task procedures.
- **Tasks:**
  - [ ] Task 1.1: Copy `/home/blake/repos/experiments/cca-plugin/templates/tasks/CLAUDE.md` to `/home/blake/repos/task-workflow-plugin/templates/CLAUDE.md`
  - [ ] Task 1.2: Commit to task-workflow repo with message "add: CLAUDE.md task procedures template"
  - [ ] Task 1.3: Verify task-workflow `templates/` now has 3 files: `CLAUDE.md`, `main.md`, `global-task-manager.md`
- **Acceptance Criteria:**
  - [ ] AC1: `ls /home/blake/repos/task-workflow-plugin/templates/` shows exactly 3 files: CLAUDE.md, main.md, global-task-manager.md
  - [ ] AC2: Content of new CLAUDE.md matches the source from CCA
- **Files:**
  - `/home/blake/repos/task-workflow-plugin/templates/CLAUDE.md` — new file (copied from CCA)
- **Dependencies:** None

#### Phase 2: Strip embedded templates from CCA and update existing skills
- **Objective:** Remove CCA's bundled templates directory and update all 3 existing skills to reference task-workflow as the template source, fix persona references, and correct cross-skill pointers.
- **Tasks:**
  - [ ] Task 2.1: Delete the entire `templates/tasks/` directory from CCA. This directory contains: `CLAUDE.md` (real file), `global-task-manager.md` (symlink to task-workflow), `main-template.md` (symlink to task-workflow). Remove the directory and all contents.
  - [ ] Task 2.2: Update `/home/blake/repos/experiments/cca-plugin/skills/setup/SKILL.md`:
    - Lines 38-43: Replace the template-copy instructions that say "use the templates bundled with this plugin" and reference `templates/tasks/` with instructions to find templates at `~/.claude/plugins/task-workflow/templates/`. The new instructions should copy: `CLAUDE.md` to `tasks/CLAUDE.md`, `main.md` to `tasks/main-template.md`, `global-task-manager.md` to `tasks/global-task-manager.md`.
    - Line 10: Replace `You are Lem, a friendly AI development coach.` with `You are a friendly AI development coach.`
    - Lines 24-25: Replace the welcome message referencing "I'm Lem" — change `> Welcome to Claude Code Architects! I'm Lem, and I'll be your development coach.` to `> Welcome to Claude Code Architects! I'll be your development coach.`
  - [ ] Task 2.3: Update `/home/blake/repos/experiments/cca-plugin/skills/kits/SKILL.md`:
    - Line 19: Change `tasks/planning/T001-<slug>/kit.yml` to `kit.yml` (project root). The full line becomes: `3. When they pick one, copy it to `kit.yml``
  - [ ] Task 2.4: Update `/home/blake/repos/experiments/cca-plugin/skills/prd/SKILL.md`:
    - Line 10: Replace `You are Lem, helping a student create a Product Requirements Document (PRD).` with `You are a friendly AI development coach, helping a student create a Product Requirements Document (PRD).`
    - Line 19: Change `(created by /cca-plugin:plan, NOT this skill)` to `(created by /cca-plugin:build, NOT this skill)`
    - Lines 82-83: Change `> Next step: **Run `/cca-plugin:plan`**` to `> Next step: **Run `/cca-plugin:build`**`
- **Acceptance Criteria:**
  - [ ] AC1: `templates/tasks/` directory no longer exists in CCA repo
  - [ ] AC2: `skills/setup/SKILL.md` references `~/.claude/plugins/task-workflow/templates/` for all 3 template files (CLAUDE.md, main.md, global-task-manager.md)
  - [ ] AC3: `skills/setup/SKILL.md` contains no "Lem" persona references
  - [ ] AC4: `skills/kits/SKILL.md` line 19 places kit at `kit.yml` (project root), not inside tasks/
  - [ ] AC5: `skills/prd/SKILL.md` references `/cca-plugin:build` (not `/cca-plugin:plan`) in both line 19 and lines 82-83
  - [ ] AC6: `skills/prd/SKILL.md` contains no "Lem" persona references
  - [ ] AC7: `grep -r "Lem" skills/` returns zero matches
- **Files:**
  - `/home/blake/repos/experiments/cca-plugin/templates/tasks/` — delete entire directory
  - `/home/blake/repos/experiments/cca-plugin/skills/setup/SKILL.md` — update template paths (lines 38-43), remove Lem persona (lines 10, 24-25)
  - `/home/blake/repos/experiments/cca-plugin/skills/kits/SKILL.md` — update kit destination (line 19)
  - `/home/blake/repos/experiments/cca-plugin/skills/prd/SKILL.md` — update persona (line 10), update skill references (lines 19, 82-83)
- **Dependencies:** Phase 1 must be complete (task-workflow must have all 3 templates before CCA stops bundling them)

#### Phase 3: Create `/cca-plugin:build` orchestrator skill
- **Objective:** Create the student-friendly build orchestrator that drives the full task-workflow lifecycle by spawning task-workflow agents.
- **Tasks:**
  - [ ] Task 3.1: Create directory `/home/blake/repos/experiments/cca-plugin/skills/build/`
  - [ ] Task 3.2: Create `/home/blake/repos/experiments/cca-plugin/skills/build/SKILL.md` with the following structure:
    - **Frontmatter:** name: build, description: orchestrates the full build workflow, user_invocable: true
    - **Persona:** Friendly AI development coach (not Lem)
    - **Step 1 - Read PRD:** Read `prd.md` from project root. If missing, tell student to run `/cca-plugin:prd` first.
    - **Step 2 - Create task:** Get next ID from `tasks/global-task-manager.md`, create `tasks/planning/TXXX-<slug>/main.md` from template (`tasks/main-template.md`), fill Task section with PRD summary, set status PLANNING, update GTM.
    - **Step 3 - Plan:** Spawn `task-workflow:plan` agent (via Task tool, run_in_background=true). Wait for task-notification. Read main.md to verify status is PLAN_REVIEW.
    - **Step 4 - Plan Review:** Spawn `task-workflow:review-plan` agent. Wait for notification. Read main.md. If READY, proceed. If NEEDS_WORK, re-spawn planner (max 3 cycles). If still not ready, set BLOCKED.
    - **Step 5 - Present plan to student:** When status is READY, present the plan summary to the student. Ask for confirmation before executing. Move task from `tasks/planning/` to `tasks/active/`.
    - **Step 6 - Execute loop:** For each phase: spawn `task-workflow:execute` agent, wait for notification, then spawn `task-workflow:review-code` agent. If PASS, move to next phase. If REVISE, re-spawn executor (max 3 cycles). If FAIL, set BLOCKED.
    - **Step 7 - Complete:** Move task from `tasks/active/` to `tasks/completed/`. Update GTM. Report success to student with summary.
    - **Key rules section:** Always run_in_background=true. Never TaskOutput on agent IDs. Always use `task-workflow:` prefix for agent names. Max 3 REVISE cycles per phase, max 3 NEEDS_WORK cycles for plan review. Student-friendly language throughout. Commit after each phase completion.
- **Acceptance Criteria:**
  - [ ] AC1: `/home/blake/repos/experiments/cca-plugin/skills/build/SKILL.md` exists with valid frontmatter
  - [ ] AC2: Skill spawns agents with `task-workflow:` prefix (plan, review-plan, execute, review-code)
  - [ ] AC3: Skill handles full lifecycle: PRD check, task creation, planning, plan review, execution loop, completion
  - [ ] AC4: Skill enforces iteration limits (max 3 REVISE, max 3 NEEDS_WORK)
  - [ ] AC5: Skill uses student-friendly language, no jargon without explanation
  - [ ] AC6: Skill includes directory transitions (planning to active, active to completed)
  - [ ] AC7: Skill presents plan to student for confirmation before execution begins
- **Files:**
  - `/home/blake/repos/experiments/cca-plugin/skills/build/SKILL.md` — new file
- **Dependencies:** Phase 2 must be complete (PRD skill must reference `/cca-plugin:build`, not `/cca-plugin:plan`)

#### Phase 4: Install script and plugin.json cleanup
- **Objective:** Provide a single install command that sets up both plugins, and add missing metadata to CCA's plugin.json.
- **Tasks:**
  - [ ] Task 4.1: Create `/home/blake/repos/experiments/cca-plugin/install.sh`:
    - Shebang: `#!/usr/bin/env bash`
    - Set -e for fail-fast
    - Define PLUGIN_DIR as `~/.claude/plugins`
    - Clone or pull task-workflow: if `$PLUGIN_DIR/task-workflow` exists, `git -C pull`; else `git clone https://github.com/blakesims/task-workflow-plugin.git $PLUGIN_DIR/task-workflow`
    - Clone or pull cca-plugin: if `$PLUGIN_DIR/cca-plugin` exists, `git -C pull`; else `git clone <cca-repo-url> $PLUGIN_DIR/cca-plugin`
    - Single success message: "Both plugins installed. Open a project and run /cca-plugin:setup to get started."
  - [ ] Task 4.2: Update `/home/blake/repos/experiments/cca-plugin/.claude-plugin/plugin.json`:
    - Add `"author": { "name": "Blake Sims", "url": "https://github.com/blakesims" }`
    - Add `"repository": "<cca-repo-url>"`
    - Follow the format used in task-workflow's plugin.json
- **Acceptance Criteria:**
  - [ ] AC1: `install.sh` is executable and handles idempotent installs (clone if missing, pull if exists)
  - [ ] AC2: `install.sh` installs both task-workflow and cca-plugin to `~/.claude/plugins/`
  - [ ] AC3: `plugin.json` has author and repository fields matching task-workflow format
  - [ ] AC4: Running `bash install.sh` twice in a row does not error
- **Files:**
  - `/home/blake/repos/experiments/cca-plugin/install.sh` — new file
  - `/home/blake/repos/experiments/cca-plugin/.claude-plugin/plugin.json` — add author + repository fields
- **Dependencies:** Phases 1-3 should be complete so the install script installs a working system

### Decision Matrix

#### Open Questions (Need Human Input)
| # | Question | Options | Impact | Resolution |
|---|----------|---------|--------|------------|
| 1 | What is the CCA plugin's git repository URL for install.sh and plugin.json? | A) `https://github.com/blakesims/cca-plugin` B) Different URL C) Not yet published — use placeholder | Affects install.sh clone URL and plugin.json repository field | RESOLVED: `git@github.com:blakesims/cca-plugin.git` |
| 2 | Should the build skill present the full plan details to the student, or just a summary? | A) Full phase breakdown B) Brief summary (objective + phase count) C) Summary with option to expand | Affects student experience — too much detail may overwhelm beginners | RESOLVED: C) Summary with option to expand |
| 3 | Should the `templates/kits/` directory remain in CCA, or should kits also move to task-workflow? | A) Keep in CCA (kits are student-experience, CCA's domain) B) Move to task-workflow | Kits are student-specific content so likely CCA's domain, but worth confirming | RESOLVED: A) Keep in CCA |

#### Decisions Made (Autonomous)
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Agent prefix in build skill | `task-workflow:` | Matches pattern in orchestrate SKILL.md; CCA is an operator on top of task-workflow, not its own agent provider |
| Persona replacement | "You are a friendly AI development coach" | Removes Lem branding while maintaining warm student-facing tone; consistent across all skills |
| Template mapping names | CLAUDE.md to tasks/CLAUDE.md, main.md to tasks/main-template.md, global-task-manager.md to tasks/global-task-manager.md | Preserves current naming convention students see in their project; main.md becomes main-template.md to avoid confusion with task main.md files |
| install.sh location | CCA repo root | Students discover CCA first (it's the user-facing plugin); install.sh lives where they land |
| Delete templates/tasks/ entirely | Remove directory, not just files | Both symlinks and the CLAUDE.md file should go; the directory itself has no purpose once templates live in task-workflow |

---

## Plan Review
- **Gate:** —
- **Reviewed:** —
- **Summary:** —
- **Issues:** —
- **Open Questions Finalized:** —

> Details: `plan-review.md`

---

## Execution Log

### Phase 1: Move task procedures template to task-workflow
- **Status:** —
- **Started:** —
- **Completed:** —
- **Commits:** —
- **Files Modified:** —
- **Notes:** —
- **Blockers:** —

### Phase 2: Strip embedded templates from CCA and update existing skills
- **Status:** —
- **Started:** —
- **Completed:** —
- **Commits:** —
- **Files Modified:** —
- **Notes:** —
- **Blockers:** —

### Phase 3: Create /cca-plugin:build orchestrator skill
- **Status:** —
- **Started:** —
- **Completed:** —
- **Commits:** —
- **Files Modified:** —
- **Notes:** —
- **Blockers:** —

### Phase 4: Install script and plugin.json cleanup
- **Status:** —
- **Started:** —
- **Completed:** —
- **Commits:** —
- **Files Modified:** —
- **Notes:** —
- **Blockers:** —

---

## Code Review Log

### Phase 1
- **Gate:** —
- **Reviewed:** —
- **Issues:** —
- **Summary:** —

> Details: `code-review-phase-1.md`

### Phase 2
- **Gate:** —
- **Reviewed:** —
- **Issues:** —
- **Summary:** —

> Details: `code-review-phase-2.md`

### Phase 3
- **Gate:** —
- **Reviewed:** —
- **Issues:** —
- **Summary:** —

> Details: `code-review-phase-3.md`

### Phase 4
- **Gate:** —
- **Reviewed:** —
- **Issues:** —
- **Summary:** —

> Details: `code-review-phase-4.md`

---

## Completion
- **Completed:** 2026-02-10
- **Summary:** All 4 phases landed in single commit `a352d34`. Templates moved to task-workflow, embedded templates stripped, skills updated (no Lem refs, correct cross-refs), build orchestrator created, install.sh + plugin.json metadata added.
- **Learnings:** Executor completed all phases in one pass but didn't backfill execution log. Task doc lagged behind actual state.
