#!/usr/bin/env bash
# CCA Plugin — Status line script
# Reads session JSON from stdin + .cca-state from project root
# Zero external dependencies (uses python3 instead of jq)

input=$(cat)

# Parse JSON with python3 (no jq needed — python is required for the project anyway)
read -r MODEL PCT <<< "$(echo "$input" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    model = d.get('model', {}).get('display_name', 'Claude')
    pct = int(float(d.get('context_window', {}).get('used_percentage', 0)))
    print(f'{model} {pct}')
except: print('Claude 0')
" 2>/dev/null || echo "Claude 0")"

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
