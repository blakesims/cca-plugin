# Kit Schema Reference

Kits are YAML files that define a project type for students to build. Each kit provides customisation questions, default values, a PRD template, and build scope for task decomposition.

## File location

`templates/kits/{kit-name}.yml` in the plugin directory.

## Top-level fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name of the kit |
| `description` | Yes | 1-2 sentence description shown to students |
| `version` | Yes | Semver string |
| `defaults` | Yes | Default values for all configurable keys |
| `levels` | Yes | Progressive customisation levels |
| `build_scope` | Yes | Task decomposition boundaries |
| `prd_template` | Yes | Mustache-style template for generating the PRD |

## Progressive customisation (`levels`)

Each level includes all questions from levels below it. The PRD skill asks the student which level they want, then asks questions for that level + all lower levels. Keys not asked use values from `defaults`.

```yaml
levels:
  - name: Quick Start
    description: Sensible defaults, start in minutes
    questions:
      - key: app_name
        question: "What do you want to call your app?"
        example: "my-app"
      - key: use_case
        question: "What's the main use case?"
        options:
          option_a: "Description of option A"
          option_b: "Description of option B"

  - name: Customise
    description: Pick your preferences
    questions: [...]

  - name: Architect
    description: Full control
    questions: [...]

  - name: Freeform
    description: Blank canvas
    type: conversation  # No template — free conversation instead
```

## Build scope (`build_scope`)

Defines how the PRD should be decomposed into tasks. Each scope group becomes a separate task with its own plan → execute → review cycle.

```yaml
build_scope:
  - name: Core Functionality
    slug: core
    description: >
      What this task delivers in plain English.
      Should be a complete, testable increment.
    always_included: true
    features:
      - Feature 1
      - Feature 2
    depends_on: []  # No dependencies — this is the foundation
    success_criteria:
      - "Testable outcome 1"
      - "Testable outcome 2"
    agent_notes: >
      Instructions passed to the planner/executor/reviewer.
      Calibrate for student context. Explicitly state what is
      OUT OF SCOPE for this task.

  - name: Optional Feature Group
    slug: feature-group
    description: >
      What this adds on top of the core.
    condition: "ui == desktop"  # Only active if student chose desktop UI
    depends_on: [core]  # Must be built after core
    features: [...]
    success_criteria: [...]
    agent_notes: >
      The core already exists. This task ONLY builds [this feature].
      Import existing modules — do not rewrite them.
```

### Scope group fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Human-readable task name |
| `slug` | Yes | URL-safe identifier, used in task directory names |
| `description` | Yes | What this task delivers — shown to students |
| `always_included` | No | If `true`, always active regardless of conditions |
| `condition` | No | Expression evaluated against student's choices |
| `depends_on` | No | List of slugs that must be built first |
| `features` | Yes | Bullet list of what's included in this task |
| `success_criteria` | Yes | Testable outcomes for the code reviewer |
| `agent_notes` | No | Context passed to planner/executor/reviewer agents. Use this to calibrate for student projects and explicitly exclude out-of-scope work |

### Condition expressions

Conditions reference keys from the student's choices (the same keys used in `defaults` and `levels`):

- `"ui == desktop"` — exact match
- `"ui != terminal"` — not equal
- `"any(hotkey, autopaste, vad)"` — true if any of these keys are truthy
- `"streaming == true"` — boolean check

### Design principles

1. **First scope group should be a working app** — The core task should deliver something the student can run and test. Everything else is enhancement.

2. **Each group is independently plannable** — A planner should be able to create a complete plan for one group without needing to plan the others. Use `agent_notes` to tell it what already exists.

3. **Keep groups to 2-4** — More than 4 means the kit is too complex. Split into multiple kits instead.

4. **`agent_notes` prevent scope creep** — Explicitly state what is NOT in scope. Without this, planners will try to solve everything.

5. **`success_criteria` feeds the reviewer** — These become the acceptance criteria the code reviewer checks against. Keep them concrete and testable.

## PRD template

Uses mustache-style substitution:

- `{{key}}` — replace with value
- `{{#key_value}}text{{/key_value}}` — include text only if `key` equals `value`
- `{{^key}}text{{/key}}` — include text only if `key` is false/empty

The PRD template should have conditional sections that map to scope groups, so each task gets only the relevant PRD content.

## Example

See `templates/kits/voice-to-text.yml` for a complete working example.
