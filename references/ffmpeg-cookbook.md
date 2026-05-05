# ffmpeg 命令手册

本文档收录抖音视频二创全流程中用到的关键 ffmpeg 命令和参数说明。

## 目录

1. [M3U8 下载](#m3u8-下载)
2. [片段裁剪](#片段裁剪)
3. [竖屏转换](#竖屏转换)
4. [慢动作特效](#慢动作特效)
5. [字幕烧录](#字幕烧录)
6. [BGM 混音](#bgm-混音)
7. [全链路渲染模板](#全链路渲染模板)

---

## M3U8 下载

```bash
ffmpeg -i "M3U8_URL" -c copy -bsf:a aac_adtstoasc output.mp4
```

参数：
- `-c copy`：不重新编码，直接拷贝流（速度最快）
- `-bsf:a aac_adtstoasc`：将 AAC 从 ADTS 格式转 MP4 兼容格式
- 可选 `-user_agent "Mozilla/5.0..."` 设置 UA 绕过简单反爬
- 可选 `-headers "Referer: https://live.douyin.com"` 设置 Referer

注意事项：
- 下载时间 = 视频时长（codec copy 无编解码开销）
- 1小时 1080p 大约 3GB
- 若中断，输出文件可能损坏（moov atom 未写入）
- 修复损坏文件：`ffmpeg -i damaged.mp4 -c copy fixed.mp4`（不一定成功）

---

## 片段裁剪

### 无损裁剪（推荐，codec copy）

```bash
ffmpeg -ss 01:20:00 -to 01:21:00 -i source.mp4 -c copy clip.mp4
```

参数：
- `-ss` 放在 `-i` 前面：快速 seek（按关键帧）
- `-to`：结束时间点（绝对时间）
- 或 `-t DURATION`：持续时长（相对开始点）

### 精确裁剪（需要时，重新编码）

```bash
ffmpeg -i source.mp4 -ss 01:20:00 -to 01:21:00 -c:v libx264 -preset fast -c:a aac clip.mp4
```

`-ss` 放 `-i` 后面：逐帧精确 seek，但慢。

### between 滤镜裁剪

```bash
ffmpeg -i source.mp4 -vf "select='between(t,START,END)',setpts=N/FRAME_RATE/TB" \
  -af "aselect='between(t,START,END)',asetpts=N/SR/TB" output.mp4
```

---

## 竖屏转换

### 方案一：模糊背景 + 居中竖屏（推荐）

两步法避免叠加 bug：

```bash
# 第一步：生成模糊背景
ffmpeg -i input.mp4 -vf \
  "scale=1080:6080:force_original_aspect_ratio=increase, \
   boxblur=20:5, \
   crop=1080:1920" \
  -c:v libx264 -preset fast -crf 23 bg.mp4

# 第二步：叠加清晰前景
ffmpeg -i bg.mp4 -i input.mp4 -filter_complex \
  "[1:v]scale=1080:-1[fg]; \
   [0:v][fg]overlay=(W-w)/2:(H-h)/2:format=auto" \
  -c:v libx264 -preset fast -crf 23 vertical.mp4
```

### 方案二：drawbox 遮盖

用于遮盖不想显示的画面区域（如话题标签文字）：

```bash
ffmpeg -i input.mp4 -vf \
  "drawbox=x=0:y=ih-200:w=iw:h=200:color=black@1.0:t=fill" \
  -c:v libx264 -preset fast output.mp4
```

参数：
- `y=ih-200`：从底部向上 200px
- `color=black@1.0`：不透明黑色（@1.0 = alpha=1）
- `t=fill`：填充矩形

### 方案三：裁剪 + 缩放（简单粗暴，不推荐）

```bash
ffmpeg -i input.mp4 -vf \
  "crop=ih*9/16:ih,scale=1080:1920" \
  output.mp4
```

缺点：裁掉画面两侧，丢失内容。

---

## 慢动作特效

### tmix 帧混合（推荐）

核心思想：将视频分段，慢放段用 tmix 产生运动模糊。

```bash
ffmpeg -i input.mp4 -filter_complex "
  [0:v]trim=0:4,setpts=PTS-STARTPTS[v1];
  [0:v]trim=4:6.5,setpts=PTS-STARTPTS, \
    tmix=frames=3:weights='1 1 1', \
    setpts=1.5*PTS[v2];
  [0:v]trim=6.5:END,setpts=PTS-STARTPTS[v3];
  [0:a]atrim=0:4,asetpts=PTS-STARTPTS[a1];
  [0:a]atrim=4:6.5,asetpts=PTS-STARTPTS,atempo=0.67[a2];
  [0:a]atrim=6.5:END,asetpts=PTS-STARTPTS[a3];
  [v1][a1][v2][a2][v3][a3]concat=n=3:v=1:a=1
" output.mp4
```

参数说明：
- `tmix=frames=3`：混合前后各1帧（共3帧），产生运动模糊
- `weights='1 1 1'`：等权重混合
- `setpts=1.5*PTS`：慢放 1.5 倍
- `atempo=0.67`：音频同步（1/1.5 ≈ 0.67）
- `atempo` 范围：0.5-2.0，每个 filter 只能改 2 倍

### minterpolate 运动补偿（质量最好但极慢）

```bash
ffmpeg -i input.mp4 -vf \
  "minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1" \
  -c:v libx264 output.mp4
```

**不推荐**：速度约 0.05x 实时，60 秒片段需 ~20 分钟。macOS 上易被 SIGTERM。

### setpts 抽帧（不推荐，会卡顿）

```bash
ffmpeg -i input.mp4 -vf "setpts=2.0*PTS" -af "atempo=0.5" output.mp4
```

缺点：帧率减半，慢放段明显卡顿。

---

## 字幕烧录

### ASS 字幕（推荐，需 libass）

```bash
ffmpeg -i input.mp4 -vf "ass=subtitles.ass" -c:v libx264 -preset fast -crf 23 output.mp4
```

### drawtext（无 libass 降级方案）

```bash
ffmpeg -i input.mp4 -vf \
  "drawtext=text='示例文字':fontfile=/System/Library/Fonts/PingFang.ttc: \
   fontsize=48:fontcolor=white:box=1:boxcolor=black@0.5: \
   x=(w-text_w)/2:y=h-th-100:enable='between(t,1,5)'" \
  output.mp4
```

限制：
- 每次只能显示一行文字
- 不支持复杂样式（描边、渐变）
- 中文需要字体文件路径
- 用 `enable='between(t,start,end)'` 控制显示时间

### 检查 libass 可用性

```bash
ffmpeg -filters 2>&1 | grep -E "ass|subtitles"
# 期望输出包含: ... ass ... subtitles ...
```

---

## BGM 混音

### 基础混音

```bash
ffmpeg -i video.mp4 -i bgm.mp3 -filter_complex \
  "[1:a]volume=0.25[bgm]; \
   [0:a][bgm]amix=inputs=2:duration=first" \
  -c:v copy -c:a aac -b:a 128k -shortest output.mp4
```

### 带淡入淡出的混音

```bash
ffmpeg -i video.mp4 -i bgm.mp3 -filter_complex \
  "[1:a]volume=0.25,afade=t=in:d=1.5,afade=t=out:st=59:d=3.5[bgm]; \
   [0:a][bgm]amix=inputs=2:duration=first:weights=1 0.3" \
  -c:v copy -c:a aac -b:a 128k -shortest output.mp4
```

参数：
- `afade=t=in:d=1.5`：前 1.5 秒淡入
- `afade=t=out:st=59:d=3.5`：59 秒处开始 3.5 秒淡出（总长 62.5 秒）
- `volume=0.25`：BGM 降为 25%
- `amix` weights：原声 1，BGM 0.3

### 生成测试音频（合成音）

```bash
# Sine 波（不推荐实际使用）
ffmpeg -f lavfi -i "sine=frequency=440:duration=60" sine.wav

# 白噪声（不推荐）
ffmpeg -f lavfi -i "anoisesrc=d=60:c=pink" noise.wav

# 使用 aevalsrc 生成简单旋律
ffmpeg -f lavfi -i "aevalsrc='sin(2*PI*440*t)*0.3':d=60" test.wav
```

## 全链路渲染模板

完整的三段式慢放 + 字幕 + 竖屏 + BGM 一条命令（不一定稳定，推荐分步执行）：

```bash
ffmpeg -i clip_raw.mp4 -i bgm.mp3 -filter_complex "
  # === 慢放分段 ===
  [0:v]trim=0:4,setpts=PTS-STARTPTS[v1];
  [0:v]trim=4:6.5,setpts=PTS-STARTPTS,tmix=frames=3,setpts=1.5*PTS[v2];
  [0:v]trim=6.5:62.5,setpts=PTS-STARTPTS[v3];
  [0:a]atrim=0:4,asetpts=PTS-STARTPTS[a1];
  [0:a]atrim=4:6.5,asetpts=PTS-STARTPTS,atempo=0.67[a2];
  [0:a]atrim=6.5:62.5,asetpts=PTS-STARTPTS[a3];
  # === 拼接 ===
  [v1][a1][v2][a2][v3][a3]concat=n=3:v=1:a=1[slow];
  # === 字幕 ===
  [slow]ass=subtitles.ass[subbed];
  # === 竖屏裁剪 ===
  [subbed]crop=ih*9/16:ih,scale=1080:1920:force_original_aspect_ratio=increase[fg];
  [subbed]scale=1080:6080,boxblur=20:5,crop=1080:1920[bg];
  [bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto[vout];
  # === BGM ===
  [1:a]volume=0.25,afade=t=out:st=59:d=3.5[bgm];
  [a3][bgm]amix=inputs=2:duration=first:weights=1 0.3[aout]
" -map "[vout]" -map "[aout]" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k final.mp4
```

---

## 通用参数速查

| 参数 | 说明 |
|------|------|
| `-preset fast/medium/slow` | 编码速度与质量。fast = 低质量快，slow = 高质量慢 |
| `-crf 18-28` | 质量因子。18 = 几乎无损，23 = 默认，28 = 较低质量 |
| `-c:v libx264` | H.264 编码（兼容性最好） |
| `-c:v libx265` | H.265/HEVC 编码（体积更小，兼容性差些） |
| `-c:a aac -b:a 128k` | AAC 音频 128kbps |
| `-shortest` | 输出长度 = 最短输入流长度 |
| `-movflags +faststart` | MP4 moov atom 放开头（流式播放友好） |
