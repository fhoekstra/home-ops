#!/bin/bash
# Pre-commit hook: block unencrypted *.sops.yaml files from being staged

SOPS_FILES=$(git diff --cached --name-only --diff-filter=d -- '*.sops.yaml' ':(exclude).sops.yaml')

if [ -z "$SOPS_FILES" ]; then
    exit 0
fi

EXIT=0

while IFS= read -r file; do
    # A SOPS-encrypted file contains a "sops:" key at the top level.
    # If the key is absent the file is unencrypted — block the commit.
    if ! git show ":$file" | grep -q '^sops:'; then
        printf '\033[31mError: unencrypted SOPS file staged: %s\033[0m\n' "$file"
        printf '       Encrypt it with "sops -e -i %s" before committing.\n' "$file"
        EXIT=1
    fi
done <<<"$SOPS_FILES"

exit $EXIT
