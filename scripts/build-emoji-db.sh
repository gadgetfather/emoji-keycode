#!/usr/bin/env bash
set -euo pipefail

# Fetch gemoji db.json and normalize into our schema:
#   [ { "emoji": "❤️", "names": ["heart"], "tags": [...] }, ... ]

OUT="Sources/EmojiKeycode/Resources/emojis.json"
SRC_URL="https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "error: jq not installed. brew install jq" >&2
    exit 1
fi

echo "Fetching $SRC_URL..."
RAW=$(curl -fsSL "$SRC_URL")

mkdir -p "$(dirname "$OUT")"

echo "$RAW" | jq '[
    .[]
    | select(.emoji != null)
    | {
        emoji: .emoji,
        names: ([.aliases[]?] | map(select(. != null and . != ""))),
        tags: ([.tags[]?] | map(select(. != null and . != "")))
      }
    | select(.names | length > 0)
]' > "$OUT"

COUNT=$(jq 'length' "$OUT")
echo "Wrote $COUNT entries to $OUT"
