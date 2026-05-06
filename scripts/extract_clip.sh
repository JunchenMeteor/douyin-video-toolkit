#!/bin/bash
# extract_clip.sh — 从长视频中提取片段
# 用法: ./extract_clip.sh <input.mp4> <start_time> <end_time> [output.mp4]
# 时间格式: HH:MM:SS 或 秒数
# 示例: ./extract_clip.sh source.mp4 01:21:40 01:22:40 clip_60s.mp4

set -euo pipefail

INPUT="${1:?请提供输入视频}"
START="${2:?请提供起始时间}"
END="${3:?请提供结束时间}"
OUTPUT="${4:-clip_$(date +%s).mp4}"

command -v ffmpeg >/dev/null 2>&1 || {
  echo "❌ 需要安装 ffmpeg"
  exit 1
}

if [ ! -f "$INPUT" ]; then
  echo "❌ 输入视频不存在: ${INPUT}"
  exit 1
fi

# 转换为秒数，支持 HH:MM:SS(.ms)、MM:SS(.ms) 和秒数。
to_seconds() {
  local t="$1"
  if [[ "$t" =~ ^([0-9]+):([0-9]+):([0-9]+)(\.[0-9]+)?$ ]]; then
    # HH:MM:SS
    awk -v h="${BASH_REMATCH[1]}" -v m="${BASH_REMATCH[2]}" -v s="${BASH_REMATCH[3]}${BASH_REMATCH[4]}" 'BEGIN { printf "%.3f", h * 3600 + m * 60 + s }'
  elif [[ "$t" =~ ^([0-9]+):([0-9]+)(\.[0-9]+)?$ ]]; then
    # MM:SS
    awk -v m="${BASH_REMATCH[1]}" -v s="${BASH_REMATCH[2]}${BASH_REMATCH[3]}" 'BEGIN { printf "%.3f", m * 60 + s }'
  elif [[ "$t" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    printf "%.3f" "$t"
  else
    echo "❌ 无效时间格式: ${t}" >&2
    exit 1
  fi
}

START_SEC=$(to_seconds "$START")
END_SEC=$(to_seconds "$END")
DURATION=$(awk -v start="$START_SEC" -v end="$END_SEC" 'BEGIN { printf "%.3f", end - start }')
if awk -v duration="$DURATION" 'BEGIN { exit !(duration <= 0) }'; then
  echo "❌ 结束时间必须晚于起始时间"
  exit 1
fi

OUTPUT_DIR=$(dirname "$OUTPUT")
if [ "$OUTPUT_DIR" != "." ]; then
  mkdir -p "$OUTPUT_DIR"
fi

echo "📐 裁剪片段..."
echo "   源文件: ${INPUT}"
echo "   起止: ${START} → ${END}"
echo "   时长: ${DURATION}s"
echo "   输出: ${OUTPUT}"
echo ""

ffmpeg -ss "${START}" -to "${END}" -i "${INPUT}" \
  -c copy \
  -avoid_negative_ts make_zero \
  -y \
  "${OUTPUT}" 2>&1

if [ -f "${OUTPUT}" ] && [ -s "${OUTPUT}" ]; then
  SIZE=$(du -sh "${OUTPUT}" | cut -f1)
  echo ""
  echo "✅ 裁剪完成！"
  echo "   文件: ${OUTPUT}"
  echo "   大小: ${SIZE}"
else
  echo ""
  echo "❌ 裁剪失败"
  exit 1
fi
