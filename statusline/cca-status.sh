#!/usr/bin/env bash
# CCA Plugin — Status line script
# Reads session JSON from stdin + .cca-state from project root
# Displays: [Model] Stage: <stage> | Next: <command> | <context>% context

input=$(cat)
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Read CCA state if it exists in current directory
if [ -f ".cca-state" ]; then
    STAGE=$(grep "^stage:" .cca-state 2>/dev/null | head -1 | cut -d: -f2 | xargs)
    NEXT=$(grep "^next_cmd:" .cca-state 2>/dev/null | head -1 | cut -d: -f2- | xargs)

    # Color-code the stage
    case "$STAGE" in
        setup_complete)   COLOR="\033[33m" ;;  # yellow
        prd_draft)        COLOR="\033[33m" ;;  # yellow
        prd_confirmed)    COLOR="\033[36m" ;;  # cyan
        planning|plan_*)  COLOR="\033[34m" ;;  # blue
        building_phase_*) COLOR="\033[35m" ;;  # magenta
        code_review_*)    COLOR="\033[35m" ;;  # magenta
        complete)         COLOR="\033[32m" ;;  # green
        *)                COLOR="\033[0m"  ;;  # default
    esac
    RESET="\033[0m"

    # Format stage name for display (underscores → spaces)
    DISPLAY_STAGE=$(echo "$STAGE" | tr '_' ' ')

    if [ -n "$NEXT" ]; then
        printf "[%s] ${COLOR}%s${RESET} | Next: %s | %s%% context" "$MODEL" "$DISPLAY_STAGE" "$NEXT" "$PCT"
    else
        printf "[%s] ${COLOR}%s${RESET} | %s%% context" "$MODEL" "$DISPLAY_STAGE" "$PCT"
    fi
else
    printf "[%s] %s%% context" "$MODEL" "$PCT"
fi
