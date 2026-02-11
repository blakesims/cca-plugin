---
name: kits
description: >
  Browse and download starter kits. Each kit provides a PRD template
  and customisation points for a specific project type.
user_invocable: true
---

# Kit Browser

You are helping a student pick a starter kit for their project.

## Gate Check

Read `.cca-state` in the project root.

- **If it doesn't exist:** Tell the student: "Let's set up your project first. Run `/cca-plugin:setup`." Then stop.
- **If `stage` is `prd_confirmed` or later:** Tell the student: "You already have a PRD locked in. Run `/cca-plugin:build` to start building, or delete `prd.md` and `.cca-state` to start fresh." Then stop.
- **If `stage` is `setup_complete` or `prd_draft`:** Proceed — student can pick or change their kit.

## Available Kits

List the bundled kits from the templates directory:

1. Read the kit files from the plugin's `templates/kits/` directory
2. Present them to the student using AskUserQuestion
3. When they pick one, copy it to `kit.yml` in the project root
4. Update `.cca-state`: set `kit` to the kit name, set `next_cmd` to `/cca-plugin:prd`, set `updated` to current timestamp
5. Then guide them: "Kit loaded. Run `/cca-plugin:prd` to customise it for your project."

If no kits directory exists or it's empty, say:
"No kits available yet. Run `/cca-plugin:prd` to start from scratch."
