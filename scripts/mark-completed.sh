#!/bin/sh
# Generate .yt-dlp-completed from existing transcripts.
# Extracts video IDs from transcript filenames (e.g., "Title [VIDEO_ID].txt")
# and writes them in yt-dlp archive format so they are skipped during download.

set -u

TRANSCRIPTS_DIR="/app/transcripts"
OUTPUT_FILE="/app/.yt-dlp-completed"

echo "# Videos with completed transcripts (auto-generated, do not edit)" > "$OUTPUT_FILE"

count=0
for txt in "$TRANSCRIPTS_DIR"/*.txt; do
  [ -f "$txt" ] || continue

  # Extract video ID from filename pattern: "Title [VIDEO_ID].txt"
  basename=$(basename "$txt" .txt)
  video_id=$(echo "$basename" | sed -n 's/.*\[\([^]]*\)\]$/\1/p')

  if [ -n "$video_id" ]; then
    echo "youtube $video_id" >> "$OUTPUT_FILE"
    count=$((count + 1))
  else
    echo "WARNING: Could not extract video ID from: $basename"
  fi
done

echo "Marked $count videos as completed in $OUTPUT_FILE"
