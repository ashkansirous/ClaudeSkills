#!/usr/bin/env bash
# Idempotent installer for ClaudeSkills.
# Re-run after `git pull` to pick up new skills and propagate config changes.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_dir="$HOME/.claude"
skills_dir="$claude_dir/skills"

mkdir -p "$skills_dir"

# 1. Symlink each skill folder into ~/.claude/skills/
if [ -d "$repo_root/skills" ]; then
    for dir in "$repo_root"/skills/*/; do
        [ -f "$dir/SKILL.md" ] || continue
        name=$(basename "$dir")
        target="$skills_dir/$name"
        source="${dir%/}"

        if [ -L "$target" ]; then
            existing=$(readlink "$target")
            [ "$existing" = "$source" ] && continue
            rm "$target"
        elif [ -e "$target" ]; then
            echo "warn: $target exists and is not a symlink, skipping" >&2
            continue
        fi
        ln -s "$source" "$target"
        echo "linked skill: $name"
    done
fi

# 2. Merge home/CLAUDE.md into ~/.claude/CLAUDE.md (marker-bracketed)
shared_claude="$repo_root/home/CLAUDE.md"
local_claude="$claude_dir/CLAUDE.md"
begin_marker="<!-- BEGIN ClaudeSkills shared instructions -->"
end_marker="<!-- END ClaudeSkills shared instructions -->"

if [ -f "$shared_claude" ]; then
    if [ -f "$local_claude" ] && grep -qF "$begin_marker" "$local_claude"; then
        # Replace existing block: keep everything before begin and after end, drop the middle, splice in fresh.
        tmp="${local_claude}.tmp"
        awk -v m="$begin_marker" '$0 == m {exit} {print}' "$local_claude" > "$tmp"
        printf '%s\n' "$begin_marker" >> "$tmp"
        cat "$shared_claude" >> "$tmp"
        printf '%s\n' "$end_marker" >> "$tmp"
        awk -v m="$end_marker" 'found {print} $0 == m {found=1}' "$local_claude" >> "$tmp"
        mv "$tmp" "$local_claude"
    elif [ -f "$local_claude" ]; then
        # Append block to existing file.
        printf '\n%s\n' "$begin_marker" >> "$local_claude"
        cat "$shared_claude" >> "$local_claude"
        printf '%s\n' "$end_marker" >> "$local_claude"
    else
        # Fresh file.
        printf '%s\n' "$begin_marker" > "$local_claude"
        cat "$shared_claude" >> "$local_claude"
        printf '%s\n' "$end_marker" >> "$local_claude"
    fi
    echo "merged: ~/.claude/CLAUDE.md"
fi

# 3. Deep-merge home/settings.json into ~/.claude/settings.json
#    Local wins on scalar conflict. Arrays union + dedupe. Nothing local is ever deleted.
shared_settings="$repo_root/home/settings.json"
local_settings="$claude_dir/settings.json"

if [ -f "$shared_settings" ]; then
    if ! command -v jq >/dev/null 2>&1; then
        echo "error: jq is required for settings.json merge. install jq and re-run." >&2
        exit 1
    fi

    local_obj="{}"
    [ -f "$local_settings" ] && local_obj=$(cat "$local_settings")

    jq -n \
        --argjson local  "$local_obj" \
        --argjson shared "$(cat "$shared_settings")" \
        '
        def merge(s):
          if type == "object" and (s|type) == "object" then
            reduce (s|keys[]) as $k (.;
              if has($k) then .[$k] |= merge(s[$k])
              else .[$k] = s[$k]
              end)
          elif type == "array" and (s|type) == "array" then
            (. + s) | unique
          else .
          end;
        $local | merge($shared)
        ' > "${local_settings}.tmp"
    mv "${local_settings}.tmp" "$local_settings"
    echo "merged: ~/.claude/settings.json"
fi

echo "done. restart Claude Code to pick up new skills."
