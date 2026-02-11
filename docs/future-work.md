# Future Work

Ideas and next steps that haven't been implemented yet.

## Per-stage model selection

The Task tool accepts a `model` parameter (`sonnet`, `opus`, `haiku`). The build skill could specify which model each spawned agent uses, with sensible defaults and kit-level overrides.

**Proposed defaults (build skill):**

| Agent | Default model | Rationale |
|-------|--------------|-----------|
| Planner | opus | Needs strong reasoning for architecture |
| Plan reviewer | sonnet | Checking, not creating |
| Executor | opus | Writing code — quality matters |
| Code reviewer | sonnet | Checking against criteria |
| Decomposition | sonnet | Lightweight analysis |
| Orchestrator | whatever student launched with | Student's choice |

**Kit-level override:**

```yaml
# In kit YAML — optional, falls back to build skill defaults
models:
  planner: sonnet
  executor: sonnet
  reviewer: sonnet
```

Simple kits (e.g. terminal-only CLI app) could run entirely on sonnet. Complex kits with advanced UI might want opus for planning and execution.

**Student-level override (future):**

Could tie to progressive levels:
- Quick Start → all sonnet (cheaper, faster)
- Architect → opus for planner/executor (better results)

Or let the student pick in setup/PRD phase.

## Other ideas

- **Kit marketplace** — community-contributed kits, installable via `/cca-plugin:kits`
- **Adaptive learning engine** — track student patterns across sessions, adjust teaching style
- **Progress dashboard** — HTML report showing completed tasks, code review pass rates
- **Multi-language support** — kit translations for non-English students
