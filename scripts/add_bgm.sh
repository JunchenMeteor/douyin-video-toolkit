#!/bin/bash
# add_bgm.sh — 给视频添加背景音乐
# 用法: ./add_bgm.sh <video.mp4> <bgm.mp3> [bgm_volume] [fade_out_start] [fade_out_duration] [output.mp4]
# 示例: ./add_bgm.sh video.mp4 bgm.mp3 0.25 59 3.5 output.mp4

set -euo pipefail

VIDEO="${1:?请提供视频文件}"
BGM="${2:?请提供 BGM 文件}"
VOLUME="${3:-0.25}"           # BGM 音量 (0.0-1.0)
FADE_START="${4:-59}"         # 淡出开始时间（秒）
FADE_DUR="${5:-3.5}"          # 淡出持续（秒）
OUTPUT="${6:-output_with_bgm.mp4}"

command -v ffmpeg >/dev/null 2>&1 || {
  echo "❌ 需要安装 ffmpeg"
  exit 1
}

echo "🎵 添加 BGM：${BGM}"
echo "   音量: ${VOLUME}"
echo "   淡出: ${FADE_START}s 开始, ${FADE_DUR}s 持续"
echo "   输出: ${OUTPUT}"
echo ""

ffmpeg -i "${VIDEO}" -i "${BGM}" -filter_complex \
  "[1:a]volume=${VOLUME},afade=t=in:d=1.5,afade=t=out:st=${FADE_START}:d=${FADE_DUR}[bgm]; \
   [0:a][bgm]amix=inputs=2:duration=first:weights=1 0.3" \
  -c:v copy -c:a aac -b:a 128k -shortest -movflags +faststart -y "${OUTPUT}" 2>&1

if [ -f "${OUTPUT}" ] && [ -s "${OUTPUT}" ]; then
  SIZE=$(du -sh "${OUTPUT}" | cut -f1)
  echo ""
  echo "✅ BGM 添加完成！"
  echo "   文件: ${OUTPUT}"
  echo "   大小: ${SIZE}"
else
  echo ""
  echo "❌ 混音失败"
  exit 1
fi
