#!/bin/bash
# check_env.sh — verify local dependencies for douyin-video-toolkit

set -euo pipefail

FAIL=0

check_cmd() {
  local cmd="$1"
  local hint="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "OK  ${cmd}: $(command -v "$cmd")"
  else
    echo "ERR ${cmd}: missing (${hint})"
    FAIL=1
  fi
}

check_filter() {
  local filter="$1"
  if ! command -v ffmpeg >/dev/null 2>&1; then
    return
  fi
  if ffmpeg -hide_banner -filters 2>/dev/null | grep -Eq "[[:space:]]${filter}[[:space:]]"; then
    echo "OK  ffmpeg filter: ${filter}"
  else
    echo "WARN ffmpeg filter missing: ${filter}"
  fi
}

check_cmd ffmpeg "install FFmpeg, for example: brew install ffmpeg"
check_cmd ffprobe "install FFmpeg, ffprobe is included"
check_cmd bc "install bc, for example: brew install bc"

check_filter tmix
check_filter drawtext
check_filter afade
check_filter ass
check_filter subtitles

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "Environment check failed. Install the missing required commands and retry."
  exit 1
fi

echo ""
echo "Environment check completed. Warnings may be acceptable if you do not use that feature."
