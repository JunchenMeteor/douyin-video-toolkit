#!/bin/bash
# download_replay.sh — 下载抖音直播回放
# 用法: ./download_replay.sh <M3U8_URL> [output_name]
# 示例: ./download_replay.sh "https://lf26-record-tos.bytefcdn.com/..." "我的直播"

set -euo pipefail

M3U8_URL="${1:?请提供 M3U8 URL}"
OUTPUT="${2:-douyin_replay}"

# 检查 ffmpeg
command -v ffmpeg >/dev/null 2>&1 || {
  echo "❌ 需要安装 ffmpeg: brew install ffmpeg"
  exit 1
}
command -v ffprobe >/dev/null 2>&1 || {
  echo "❌ 需要安装 ffprobe: brew install ffmpeg"
  exit 1
}

if [[ ! "$M3U8_URL" =~ ^https?:// ]]; then
  echo "❌ M3U8 URL 必须以 http:// 或 https:// 开头"
  exit 1
fi

# 检查磁盘空间 (至少 5GB)
AVAIL=$(df -Pk . | awk 'NR==2 {print int($4 / 1024 / 1024)}')
if [ "$AVAIL" -lt 5 ]; then
  echo "⚠️  可用磁盘空间不足 5GB (当前: ${AVAIL}GB)"
  echo "   继续下载可能导致失败"
  read -p "   是否继续? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

OUTPUT_FILE="${OUTPUT}.mp4"
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ "$OUTPUT_DIR" != "." ]; then
  mkdir -p "$OUTPUT_DIR"
fi

echo "📥 开始下载..."
echo "   URL: ${M3U8_URL}"
echo "   输出: ${OUTPUT_FILE}"
echo ""

ffmpeg -i "${M3U8_URL}" \
  -c copy \
  -bsf:a aac_adtstoasc \
  -movflags +faststart \
  -y \
  "${OUTPUT_FILE}" 2>&1 | tee "${OUTPUT}_download.log"

if [ -f "${OUTPUT_FILE}" ] && [ -s "${OUTPUT_FILE}" ]; then
  SIZE=$(du -sh "${OUTPUT_FILE}" | cut -f1)
  DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "${OUTPUT_FILE}" 2>/dev/null || echo "unknown")
  echo ""
  echo "✅ 下载完成！"
  echo "   文件: ${OUTPUT_FILE}"
  echo "   大小: ${SIZE}"
  echo "   时长: ${DURATION} 秒"
  echo "   日志: ${OUTPUT}_download.log"
else
  echo ""
  echo "❌ 下载失败或文件为空"
  exit 1
fi
