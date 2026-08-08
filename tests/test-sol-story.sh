#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tool="$root/tools/sol-story.py"
manifest="$root/sol-project/story/story.json"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

python3 "$tool" "$manifest" --summary >/dev/null

cat >"$tmp/valid.json" <<'JSON'
{
  "contract": 1,
  "map": "E1M1",
  "events": [
    {
      "id": 1,
      "key": "arrival.start",
      "objective_id": 1,
      "subtitle_id": 1,
      "radio_id": 1
    }
  ],
  "objectives": [{"id": 1, "key": "arrival.objective"}],
  "subtitles": [{"id": 1, "key": "arrival.subtitle"}],
  "radio": [{"id": 1, "key": "arrival.radio"}]
}
JSON
python3 "$tool" "$tmp/valid.json" >/dev/null

cat >"$tmp/duplicate.json" <<'JSON'
{
  "contract": 1,
  "map": "E1M1",
  "events": [],
  "objectives": [
    {"id": 1, "key": "a"},
    {"id": 1, "key": "b"}
  ],
  "subtitles": [],
  "radio": []
}
JSON
if python3 "$tool" "$tmp/duplicate.json" >/dev/null 2>&1; then
    printf 'duplicate story IDs were accepted\n' >&2
    exit 1
fi

cat >"$tmp/missing-ref.json" <<'JSON'
{
  "contract": 1,
  "map": "E1M1",
  "events": [{"id": 1, "key": "arrival.start", "objective_id": 99}],
  "objectives": [],
  "subtitles": [],
  "radio": []
}
JSON
if python3 "$tool" "$tmp/missing-ref.json" >/dev/null 2>&1; then
    printf 'dangling story reference was accepted\n' >&2
    exit 1
fi
