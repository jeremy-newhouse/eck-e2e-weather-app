#!/bin/bash
# Heuristic injection — load active heuristics into agent context
# Used by SessionStart hook
# Reads .claude/heuristics/heuristics.md, filters active heuristics,
# outputs top 10 by confidence as numbered guidance rules.
# Silent exit (no output) if file missing/empty or no active heuristics.
# Exit 0 always (non-blocking)

HEURISTICS_FILE="$CLAUDE_PROJECT_DIR/.claude/heuristics/heuristics.md"

# Silent exit if file missing or empty
if [ ! -s "$HEURISTICS_FILE" ]; then
  exit 0
fi

# Parse heuristics: extract title, confidence, trigger, rule, status
# Each heuristic entry is a ### heading followed by bullet fields
# Output tab-separated: confidence\ttitle\ttrigger\trule\tstatus
PARSED=$(awk '
  /^### / {
    if (title != "" && status == "active") {
      printf "%s\t%s\t%s\t%s\n", confidence, title, trigger, rule
    }
    title = substr($0, 5)
    confidence = ""; trigger = ""; rule = ""; status = ""
  }
  /^\- \*\*Confidence\*\*:/ {
    gsub(/.*\*\*Confidence\*\*: */, "")
    confidence = $0 + 0
  }
  /^\- \*\*Trigger\*\*:/ {
    gsub(/.*\*\*Trigger\*\*: */, "")
    trigger = $0
  }
  /^\- \*\*Rule\*\*:/ {
    gsub(/.*\*\*Rule\*\*: */, "")
    rule = $0
  }
  /^\- \*\*Status\*\*:/ {
    gsub(/.*\*\*Status\*\*: */, "")
    gsub(/ *$/, "")
    status = $0
  }
  END {
    if (title != "" && status == "active") {
      printf "%s\t%s\t%s\t%s\n", confidence, title, trigger, rule
    }
  }
' "$HEURISTICS_FILE")

# Silent exit if no active heuristics
if [ -z "$PARSED" ]; then
  exit 0
fi

# Sort by confidence descending, take top 10, format as numbered rules
OUTPUT=$(echo "$PARSED" | sort -t$'\t' -k1 -rn | head -10 | awk -F'\t' '{
  printf "  %d. [%.2f] When %s: %s\n", NR, $1, $3, $4
}')

# Output guidance block
echo ""
echo "## Active Heuristics (Top 10)"
echo ""
echo "$OUTPUT"
echo ""

exit 0
