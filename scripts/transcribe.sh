#!/bin/sh
# Batch convert GCISD webm files -> wav -> txt using whisper-cli
# - Keeps original .webm files
# - Deletes .wav after successful transcription
# - Skips files where .txt already exists

set -u  # treat unset variables as errors

MODEL_PATH="/app/models/ggml-tiny.en-q5_1.bin"

if [ ! -f "$MODEL_PATH" ]; then
  echo "Model not found at '$MODEL_PATH'"
  echo "Please ensure the whisper model is available."
  exit 1
fi

for webm in *.webm; do
  # Skip if no webm files (glob didn't match)
  [ -f "$webm" ] || continue

  base="${webm%.webm}"
  opus="${base}.opus"
  wav_stereo="${base}.stereo.wav"
  wav="${base}.wav"
  txt="/app/transcripts/${base}.txt"

  echo "----------------------------------------"
  echo "Processing: $webm"

  # Skip if transcript already exists
  if [ -f "$txt" ]; then
    echo "Transcript exists, skipping: $txt"
    continue
  fi

  # If opus doesn't exist, create it
  if [ -f "$opus" ]; then
    echo "Found existing opus, will reuse: $opus"
  else
    mkvextract tracks "$webm" 0:"$opus"

    if [ $? -ne 0 ]; then
      echo "ERROR: mkvextract failed for '$webm'. Skipping."
      rm -f "$opus" 2>/dev/null || true
      continue
    fi
  fi

  # If wav doesn't exist, create it
  if [ -f "$wav" ]; then
    echo "Found existing wav, will reuse: $wav"
  else
    echo "Converting to wav: $wav"
    # Some GCISD videos has offset channels that cancel each other when mixing L+R together
    # Take just left channel
    opusdec --rate 16000 --force-wav "$opus" - \
      | sox -t wav - -c 1 "$wav" remix 1

    if [ $? -ne 0 ]; then
      echo "ERROR: opusdec failed for '$opus'. Skipping."
      rm -f "$wav" 2>/dev/null || true
      continue
    fi
  fi

  # Transcribe wav -> txt
  echo "Transcribing to txt: $txt"
  if whisper-cli -m "$MODEL_PATH" -f "$wav" > "$txt"; then
    echo "Transcription successful. Deleting wav: $wav"
    rm -f "$opus"
    rm -f "$wav"
  else
    echo "ERROR: whisper-cli failed for '$wav'."
    echo "Keeping wav for debugging and deleting incomplete txt (if any)."
    rm -f "$txt" 2>/dev/null || true
  fi

done

echo "All done."