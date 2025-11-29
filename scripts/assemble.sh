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

  # Extract date from filename and convert to sortable format (YYYY-MM-DD)
  # Handle multiple date formats:
  # 1. "Month Day, Year" (e.g., "April 28, 2025")
  # 2. "Year" at beginning (e.g., "2020 Graduation")
  # 3. "Year" after dash (e.g., "- 2021 Graduation")

  base=$(basename "$txt" .txt)

  # Try different patterns to extract a sortable date
  sortable_date="0000-00-00"

  # Pattern 1: Year at the beginning (e.g., "2020 Graduation")
  if echo "$base" | grep -q '^[0-9]\{4\} '; then
    sortable_date=$(echo "$base" | sed 's/^\([0-9]\{4\}\) .*/\1-00-00/')

  # Pattern 2: "- Year Graduation" (e.g., "- 2021 Graduation")
  elif echo "$base" | grep -q ' - [0-9]\{4\} Graduation'; then
    sortable_date=$(echo "$base" | sed 's/.* - \([0-9]\{4\}\) Graduation.*/\1-00-00/')

  # Pattern 3: "Month Day, Year" anywhere (e.g., "- March 28, 2022" or "August 19, 2021")
  # Also handles "Month Day ,Year" with space before comma
  elif echo "$base" | grep -qE '(January|February|March|April|May|June|July|August|September|October|November|December) [0-9]{1,2} ?,? ?[0-9]{4}'; then
    # Extract month, day, year (handling optional space before comma)
    month=$(echo "$base" | sed -n 's/.*\(January\|February\|March\|April\|May\|June\|July\|August\|September\|October\|November\|December\) [0-9]\{1,2\} \?,\? \?[0-9]\{4\}.*/\1/p')
    day=$(echo "$base" | sed -n 's/.*\(January\|February\|March\|April\|May\|June\|July\|August\|September\|October\|November\|December\) \([0-9]\{1,2\}\) \?,\? \?[0-9]\{4\}.*/\2/p')
    year=$(echo "$base" | sed -n 's/.*\(January\|February\|March\|April\|May\|June\|July\|August\|September\|October\|November\|December\) [0-9]\{1,2\} \?,\? \?\([0-9]\{4\}\).*/\2/p')

    # Convert month name to number
    case "$month" in
      January) month_num=01 ;;
      February) month_num=02 ;;
      March) month_num=03 ;;
      April) month_num=04 ;;
      May) month_num=05 ;;
      June) month_num=06 ;;
      July) month_num=07 ;;
      August) month_num=08 ;;
      September) month_num=09 ;;
      October) month_num=10 ;;
      November) month_num=11 ;;
      December) month_num=12 ;;
    esac

    # Pad day with zero if needed
    day=$(printf "%02d" "$day")

    sortable_date="${year}-${month_num}-${day}"
  fi

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

  # Add transcript link to GitHub
  # URL-encode the filename for GitHub link
  encoded_name=$(echo "$base" | sed 's/ /%20/g; s/,/%2C/g; s/\[/%5B/g; s/\]/%5D/g')
  echo "**Transcript Link:** https://github.com/jirkafajfr/gcisd-watchdog/blob/mainline/transcripts/${encoded_name}.txt" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  # Add the transcript content, skipping lines with [BLANK_AUDIO], [no audio], [APPLAUSE], and [INAUDIBLE]
  grep -v '\[BLANK_AUDIO\]' "$txt" | grep -v '\[no audio\]' | grep -v '\[APPLAUSE\]' | grep -v '\[INAUDIBLE\]' >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
done

# Clean up temporary file
rm -f "$temp_list"

echo "GPT dataset generation complete: $OUTPUT_FILE"
