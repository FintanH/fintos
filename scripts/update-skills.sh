#!/usr/bin/env bash
# Refresh the skill clones in ~/Developer/AgentSkills.
# trailofbits-curated/ is a curated COPY — refresh it manually by re-copying
# the wanted skills from trailofbits/skills/ after this runs.
set -euo pipefail
A="$HOME/Developer/AgentSkills"
for repo in "$A/obra/superpowers" "$A/mattpocock/skills" "$A/trailofbits/skills"; do
  if [ -d "$repo/.git" ]; then
    echo "== $repo =="
    git -C "$repo" pull --ff-only
  else
    echo "skip (not a git clone): $repo" >&2
  fi
done
echo "Reminder: re-copy trailofbits-curated/ from trailofbits/skills/ if a curated skill changed."
