#!/bin/bash
# slowmo_vertical.sh — 三段式慢放 + 竖屏转换 + drawbox遮盖
# 用法: ./slowmo_vertical.sh <input.mp4> <slow_start> <slow_end> <slomo_factor> [output.mp4]
# 示例: ./slowmo_vertical.sh clip.mp4 4 6.5 1.5 output.mp4

set -euo pipefail

INPUT="${1:?请提供输入视频}"
SLOW_START="${2:-4}"        # 慢放开始时间（秒）
SLOW_END="${3:-6.5}"        # 慢放结束时间（秒）
SLOMO="${4:-1.5}"           # 慢放倍率
OUTPUT="${5:-slowmo_vertical.mp4}"

command -v ffmpeg >/dev/null 2>&1 || {
  echo "❌ 需要安装 ffmpeg"
  exit 1
}

# 获取视频时长
TOTAL_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "${INPUT}")
END_TIME=$(printf "%.1f" "$TOTAL_DUR")

# 计算 atempo (不能超过 2.0，否则需要链式)
ATEMPO=$(echo "scale=4; 1.0 / ${SLOMO}" | bc)

echo "🎬 三段式慢放 + 竖屏转换..."
echo "   源文件: ${INPUT}"
echo "   时长: ${END_TIME}s"
echo "   慢放段: ${SLOW_START}s → ${SLOW_END}s"
echo "   慢放倍率: ${SLOMO}x (atempo: ${ATEMPO})"
echo "   输出: ${OUTPUT}"
echo ""

# 视频分段 + tmix 慢放 + 拼接 + 竖屏 + drawbox
ffmpeg -i "${INPUT}" -filter_complex "
  [0:v]trim=0:${SLOW_START},setpts=PTS-STARTPTS[v1];
  [0:v]trim=${SLOW_START}:${SLOW_END},setpts=PTS-STARTPTS,
    tmix=frames=3:weights='1 1 1',
    setpts=${SLOMO}*PTS[v2];
  [0:v]trim=${SLOW_END}:${END_TIME},setpts=PTS-STARTPTS[v3];
  [0:a]atrim=0:${SLOW_START},asetpts=PTS-STARTPTS[a1];
  [0:a]atrim=${SLOW_START}:${SLOW_END},asetpts=PTS-STARTPTS,atempo=${ATEMPO}[a2];
  [0:a]atrim=${SLOW_END}:${END_TIME},asetpts=PTS-STARTPTS[a3];
  [v1][a1][v2][a2][v3][a3]concat=n=3:v=1:a=1[joined];
  [joined]crop=ih*9/16:ih,scale=1080:1920:force_original_aspect_ratio=increase[fg];
  [joined]scale=1080:6080,boxblur=20:5,crop=1080:1920[bg];
  [bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto
" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart -y "${OUTPUT}" 2>&1

if [ -f "${OUTPUT}" ] && [ -s "${OUTPUT}" ]; then
  SIZE=$(du -sh "${OUTPUT}" | cut -f1)
  echo ""
  echo "✅ 完成！"
  echo "   文件: ${OUTPUT}"
  echo "   大小: ${SIZE}"
else
  echo ""
  echo "❌ 渲染失败"
  exit 1
fi
