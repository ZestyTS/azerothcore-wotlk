#!/bin/bash

MODULE_DIR="modules"
UPDATED_CONFIG_MODULES=()
NEEDS_MANUAL_ATTENTION=()

echo "🔄 Updating all git-based modules in $MODULE_DIR..."

for dir in "$MODULE_DIR"/*; do
  if [ -d "$dir/.git" ]; then
    echo "📦 Updating module: $(basename "$dir")"

    cd "$dir" || continue

    # Try pulling latest (fast-forward only)
    if ! git pull --ff-only 2>/dev/null; then
      echo "⚠️  Pull failed in $(basename "$dir"). Checking for merge conflict in conf/..."

      # Look for unmerged files in conf/
      conflict_files=$(git diff --name-only --diff-filter=U | grep '^conf/.*\.dist$')

      if [ -n "$conflict_files" ]; then
        echo "🔧 Handling conflict in conf/ for $(basename "$dir")"
        for file in $conflict_files; do
          mv "$file" "$file.old"
          echo "  → Moved $file to $file.old"
        done

        # Retry pull
        if git pull --ff-only 2>/dev/null; then
          UPDATED_CONFIG_MODULES+=("$(basename "$dir")")
        else
          echo "❌ Still failed after handling conf/ conflicts in $(basename "$dir")"
          NEEDS_MANUAL_ATTENTION+=("$(basename "$dir")")
        fi
      else
        echo "❌ Merge conflict not recoverable in $(basename "$dir")"
        NEEDS_MANUAL_ATTENTION+=("$(basename "$dir")")
      fi
    fi

    cd - >/dev/null
  fi
done

echo ""
echo "✅ Done checking modules."

# Warnings
if [ ${#UPDATED_CONFIG_MODULES[@]} -ne 0 ]; then
  echo ""
  echo "⚠️  Config files updated for the following modules (originals saved as .old):"
  for mod in "${UPDATED_CONFIG_MODULES[@]}"; do
    echo " - $mod"
  done
fi

# Errors
if [ ${#NEEDS_MANUAL_ATTENTION[@]} -ne 0 ]; then
  echo ""
  echo "❌ Manual action required for the following modules:"
  for mod in "${NEEDS_MANUAL_ATTENTION[@]}"; do
    echo " - $mod"
  done
else
  echo ""
  echo "🎉 All modules updated cleanly."
fi

