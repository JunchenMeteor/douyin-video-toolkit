---
name: douyin-video-toolkit
description: 抖音直播回放下载与短视频二次创作全流程工具。覆盖直播回放M3U8下载、视频片段裁剪、竖屏转换(9:16)、慢动作特效(tmix帧混合)、ASS字幕烧录、BGM混音、抖音创作者后台自动发布。触发条件：用户提到抖音直播回放下载、抖音视频剪辑、短视频二创、游戏直播高光、竖屏视频制作、或者需要从creator.douyin.com下载/发布视频时使用。
---

# 抖音视频二创工具包

从直播回放下载到短视频发布的全流程自动化。

## 前置条件

- **ffmpeg** (需编译 libass/librubberband 支持，`brew install ffmpeg` 默认包含)
  - 版本检查：`ffmpeg -version | grep -E "libass|rubberband"`
  - 关键 filter：drawtext 或 subtitles、tmix、afade、aevalsrc
- **xbrowser** skill — 浏览器自动化（抖音创作者后台操作）
- **macOS 环境**（本文以 macOS 为主，Linux 对应调整）

## 工作流程总览

```
直播回放下载 → 音频分析 → 片段裁剪 → 竖屏转换 → 慢放特效 → 字幕烧录 → BGM混音 → 发布
```

## Step 1: 下载抖音直播回放

### 1.1 定位回放

用 xbrowser 打开创作者后台，导航路径：
> 首页 → 内容管理 → 直播场次 → 目标场次 → 直播复盘

注意：抖音的"直播复盘"是数据分析页，不是视频播放页。回放视频嵌入在该页面中。

### 1.2 提取 M3U8 地址

在直播复盘页面打开 F12 DevTools → Network 标签，筛选 `m3u8`，找到请求 URL，格式：
```
https://lf26-record-tos.bytefcdn.com/obj/fcdnlarge2-fcdn-dy/{account_id}/push-rtmp-hs-f5.douyincdn.com_{stream_path}_record.m3u8
```

### 1.3 下载视频

```bash
ffmpeg -i "{M3U8_URL}" -c copy -bsf:a aac_adtstoasc "{output}.mp4"
```

- `-c copy`：流复制，不重新编码，速度快
- `-bsf:a aac_adtstoasc`：AAC 比特流过滤器，确保 MP4 兼容
- ⚠️ **不要中断** — 中断后 mp4 moov atom 可能未写入，文件损坏
- ⚠️ **磁盘空间** — 1 小时 1080p 约需 3GB

## Step 2: 音频分析定位高光片段

### 2.1 提取音频

```bash
ffmpeg -i source.mp4 -vn -acodec copy audio.aac
```

### 2.2 静音检测

```bash
ffmpeg -i source.mp4 -af "silencedetect=n=-30dB:d=0.5" -f null -
```

### 2.3 响度分析（定位情绪波动）

```bash
ffmpeg -i source.mp4 -af "ebur128=video=log" -f null -
```

重点：音量骤降 + 骤升区间通常是精彩反应（死亡 → 吐槽）。

## Step 3: 片段裁剪

使用 `between` 滤镜精确裁剪（推荐，避免关键帧偏移）：

```bash
ffmpeg -i source.mp4 \
  -ss START_TIME -to END_TIME \
  -c copy clip_raw.mp4
```

详细参数见 [references/ffmpeg-cookbook.md](references/ffmpeg-cookbook.md)。

## Step 4: 竖屏转换 (16:9 → 9:16)

标准短视频竖屏尺寸 **1080×1920**。

裁剪竖屏 + 模糊背景填充方案：

```bash
# 两遍处理：先做模糊背景，再叠加清晰竖屏画面
# 第一步：生成模糊背景
ffmpeg -i input.mp4 -vf \
  "scale=1080:6080,boxblur=20:5,crop=1080:1920:0:2080" \
  -c:v libx264 -preset fast blurred_bg.mp4

# 第二步：叠加
ffmpeg -i blurred_bg.mp4 -i clip_raw.mp4 -filter_complex \
  "[1:v]scale=1080:607.5:force_original_aspect_ratio=decrease[fg]; \
   [0:v][fg]overlay=(W-w)/2:(H-h)/2" \
  -c:v libx264 -preset fast vertical_out.mp4
```

或使用 `drawbox` 遮盖不需要的区域（参见 references）。

## Step 5: 慢动作特效

### 方案对比

| 方案 | 速度 | 质量 | 适用 |
|------|------|------|------|
| **tmix** (帧混合) | 快（0.95x 实时） | 流畅模糊过渡 | ✅ 推荐 |
| minterpolate (运动补偿) | 极慢（0.05x）- 放弃 | 最佳 | ❌ 不推荐 |
| setpts (抽帧) | 最快 | 卡顿 | ❌ 不推荐 |

### tmix 三段式拼接

将视频分成 normal → slow → normal 三段，通过 `concat` 拼接：

```bash
ffmpeg -i clip_raw.mp4 -filter_complex "
  [0:v]trim=0:4,setpts=PTS-STARTPTS[v1];
  [0:v]trim=4:6.5,setpts=PTS-STARTPTS,tmix=frames=3:weights='1 1 1',setpts=1.5*PTS[v2];
  [0:v]trim=6.5:60,setpts=PTS-STARTPTS[v3];
  [0:a]atrim=0:4,asetpts=PTS-STARTPTS[a1];
  [0:a]atrim=4:6.5,asetpts=PTS-STARTPTS,atempo=0.67[a2];
  [0:a]atrim=6.5:60,asetpts=PTS-STARTPTS[a3];
  [v1][a1][v2][a2][v3][a3]concat=n=3:v=1:a=1
" slowmo_output.mp4
```

说明：
- `tmix=frames=3`：混合3帧产生运动模糊
- `setpts=1.5*PTS`：1.5倍慢放
- 视频 `setpts` 和音频 `atempo` 必须同步比例（1.5x slomo → atempo=0.67）

## Step 6: 字幕烧录

### 优先方案：ASS 字幕（libass）

1. 创建 ASS 字幕文件（格式见 [references/subtitles-guide.md](references/subtitles-guide.md)）
2. 烧录：

```bash
ffmpeg -i input.mp4 -vf "ass=subtitles.ass" -c:v libx264 output.mp4
```

### 降级方案：drawtext（无 libass 时）

- drawtext 不支持多行样式，功能受限
- 用 `drawbox` 遮盖不想要的画面内容：`drawbox=y=ih-200:w=iw:h=200:color=black:t=fill`

### 字幕时机设计

| 时间 | 类型 | 内容 |
|------|------|------|
| 0.2s - 3.5s | 标题引入 | 事件描述，大字体 |
| 关键帧附近 | 高潮字幕 | 红色/醒目色，强调动作 |
| 反应段落 | 吐槽字幕 | 小字，跟随画面 |
| 结尾 2s | 话题标签 | 限字幕，**不要出现在画面中**（用 drawbox 遮挡） |

## Step 7: BGM 混音

### 选曲原则

- 优先抖音生态内音乐（汽水音乐等），无版权风险
- 风格：搞笑/轻松/中二 → 「猪突猛進」(百石元)
- 避免低频重低音（手机扬声器截止 ~200Hz）
- 320kbps MP3 足够

### 混音命令

```bash
ffmpeg -i video.mp4 -i bgm.mp3 -filter_complex \
  "[1:a]volume=0.25,afade=t=out:st=END_SEC:d=3.5[bgm]; \
   [0:a][bgm]amix=inputs=2:duration=first:weights=1 0.3" \
  -c:v copy -c:a aac -b:a 128k output.mp4
```

- `volume=0.25`：BGM 音量 25%（不压过原声）
- `afade=t=out:st=END_SEC:d=3.5`：结尾 3.5 秒淡出
- `amix`：混音，原声权重 1，BGM 权重 0.3

## Step 8: 发布到抖音

xbrowser 自动化发布流程：

1. 打开 `https://creator.douyin.com`
2. 导航到发布页（通常从首页有入口）
3. 上传视频文件
4. 填写：
   - 标题（≤30 字）
   - 简介 + 话题标签（纯文本）
   - 游戏分类（如有）
   - 正式话题标签（通过 `#添加话题` 按钮添加，获得话题页流量）
5. 确认可见性=公开、评论=允许
6. 检测通过后，留待用户确认发布

**不要替用户点击「发布」按钮**，只做到发布前最后一步。

## 常见问题

详见 [references/troubleshooting.md](references/troubleshooting.md)。

- ffmpeg 进程被 SIGKILL → 系统资源限制，拆分步骤避免长时间编码
- sharp 模块无法加载 → darwin-x64 兼容性，使用 ffmpeg 替代
- libass 不可用 → `brew reinstall ffmpeg` 或降级到已知可用版本
- 话题标签出现在画面中 → 用 `drawbox` 遮盖，不要裁剪视频内容
- macOS quarantine 标记 → `xattr -cr file.mp4`

## 参考文件

- [ffmpeg 命令手册](references/ffmpeg-cookbook.md) — 完整命令参数和最佳实践
- [字幕制作指南](references/subtitles-guide.md) — ASS 字幕格式和设计规范
- [故障排除](references/troubleshooting.md) — 详细错误场景和解决方案
- [BGM 资源](references/bgm-library.md) — 推荐 BGM 列表和下载源
