#!/bin/bash
# Setup git hooks for this repository (requires Git 2.54+)
#
# Usage:
#   ./setup-hooks.sh
#
# Hook files should be named: [subject].[event].extension
# Examples: sops.pre-commit.sh, push-apoci.post-commit.py

# --- Git version check ---
GIT_VERSION="$(git --version | sed 's/git version //')"
GIT_MAJOR="${GIT_VERSION%%.*}"
GIT_MINOR="${GIT_VERSION#*.}"
GIT_MINOR="${GIT_MINOR%%.*}"
if [[ "$GIT_MAJOR" -lt 2 ]] || [[ "$GIT_MAJOR" -eq 2 && "$GIT_MINOR" -lt 54 ]]; then
    printf '\033[31mError: Git %s is installed, but this repository requires Git 2.54+\033[0m\n' "$GIT_VERSION"
    exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/.hooks"

printf '\033[1mSyncing git hooks with %s...\033[0m\n' "$HOOKS_DIR"

# --- Track which hooks are currently registered ---
REGISTERED_HOOKS=()
while IFS='=' read -r key value; do
    [[ $key =~ ^hook\.(.+)\.event$ ]] && REGISTERED_HOOKS+=("${BASH_REMATCH[1]}")
done < <(git config --local --get-regexp '^hook\.' 2>/dev/null)

# --- Auto-discover and register hooks from files ---
ACTIVE_HOOKS=()
for hook_file in "$HOOKS_DIR"/*; do
    [[ ! -f "$hook_file" || ! -x "$hook_file" ]] && continue

    filename="$(basename "$hook_file")"

    # Parse: [subject].[event].extension
    subject="${filename%.*}" # Remove extension
    event="${subject#*.}"    # Extract event
    subject="${subject%%.*}" # Extract subject

    git config --local "hook.${subject}.event" "$event"
    git config --local "hook.${subject}.command" "$hook_file"
    printf '  ✓ %s.%s\n' "$subject" "$event"
    ACTIVE_HOOKS+=("$subject")
done

# --- Remove hooks that no longer have files ---
for registered in "${REGISTERED_HOOKS[@]}"; do
    if [[ ! " ${ACTIVE_HOOKS[@]} " =~ " ${registered} " ]]; then
        git config --local --unset "hook.${registered}.event"
        git config --local --unset "hook.${registered}.command"
        printf '  ✗ %s (removed)\n' "$registered"
    fi
done

# --- Finalize ---
if [[ ${#ACTIVE_HOOKS[@]} -gt 0 ]]; then
    # Remove hooksPath if set — conflicts with native hook config
    git config --local --unset core.hooksPath 2>/dev/null
    echo ""
    echo "Done! ${#ACTIVE_HOOKS[@]} hook(s) configured in .git/config"
else
    echo "No executable hooks found in $HOOKS_DIR"
    exit 1
fi
