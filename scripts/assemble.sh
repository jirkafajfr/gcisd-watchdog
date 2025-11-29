#!/bin/sh
# Generate GPT dataset from all transcripts into a single markdown file
# - Creates headers from filenames
# - Generates YouTube links based on video IDs
# - Outputs to gpt/dataset.md

set -u

OUTPUT_FILE="/app/gpt/dataset.md"

echo "# GCISD GPT Dataset" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process all txt files in transcripts folder, sorted chronologically
# Create a temporary file list with sortable dates
temp_list=$(mktemp)

for txt in /app/transcripts/*.txt; do
  # Skip if no txt files (glob didn't match)
  [ -f "$txt" ] || continue

  # Extract date from filename (format: "Month Day, Year")
  # Convert to sortable format (YYYY-MM-DD)
  sortable_date=$(echo "$txt" | sed -n 's/.*- \([A-Za-z]* [0-9]*, [0-9]*\).*/\1/p' | \
    awk '{
      months["January"]=1; months["February"]=2; months["March"]=3;
      months["April"]=4; months["May"]=5; months["June"]=6;
      months["July"]=7; months["August"]=8; months["September"]=9;
      months["October"]=10; months["November"]=11; months["December"]=12;
      gsub(",", "", $2);
      printf "%d-%02d-%02d", $3, months[$1], $2
    }')

  echo "$sortable_date|$txt" >> "$temp_list"
done

# Sort by date and process in chronological order
sort "$temp_list" | while IFS='|' read -r sortable_date txt; do
  # Extract base filename without path and extension
  base=$(basename "$txt" .txt)

  echo "Processing: $base"

  # Add header with filename (without .txt)
  echo "---" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "## $base" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  # Try to extract video ID from filename
  # Common yt-dlp format: [TITLE] [VIDEO_ID].webm
  # Extract the part in brackets at the end
  video_id=$(echo "$base" | sed -n 's/.*\[\([^]]*\)\]$/\1/p')

  if [ -n "$video_id" ]; then
    echo "**Video Link:** https://www.youtube.com/watch?v=$video_id" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
  fi

  # Add the transcript content, skipping lines with [BLANK_AUDIO]
  grep -v '\[BLANK_AUDIO\]' "$txt" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
done

# Clean up temporary file
rm -f "$temp_list"

echo "GPT dataset generation complete: $OUTPUT_FILE"
