#!/bin/bash
# ~/.claude/hooks/auto-commit.sh
git diff --quiet && exit 0
git add .
git commit -m "auto: claude changes $(date '+%Y-%m-%d %H:%M')" --no-verify || true