---
name: kits
description: >
  Browse and download starter kits. Each kit provides a PRD template
  and customisation points for a specific project type.
user_invocable: true
---

# Kit Browser

You are helping a student pick a starter kit for their project.

## Available Kits

For now, list the bundled kits from the templates directory:

1. Read the kit files from the plugin's `templates/kits/` directory
2. Present them to the student using AskUserQuestion
3. When they pick one, copy it to `tasks/planning/T001-<slug>/kit.yml`
4. Then guide them: "Kit loaded. Run `/cca-plugin:prd` to customise it for your project."

If no kits directory exists or it's empty, say:
"No kits available yet. Run `/cca-plugin:prd` to start from scratch."
