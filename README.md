# 🎬 抖音视频二创工具包

从**抖音直播回放下载**到**短视频二创发布**的全流程自动化工具包。

一键提取 M3U8 → 裁剪高光片段 → 竖屏转换 → 慢动作特效 → 字幕烧录 → BGM 混音 → 发布抖音。

---

## 什么情况下用？

- 你开了抖音直播，想把精彩片段剪成短视频发出去
- 游戏直播翻车/高光时刻需要慢放 + 字幕 + BGM 加工
- 需要从创作者后台下载直播回放（抖音官方不提供下载按钮）

---

## 安装

### 方式一：OpenClaw SkillHub 安装（推荐）

```
安装 douyin-video-toolkit skill
```

### 方式二：手动安装

```bash
# 克隆到 OpenClaw 技能目录
git clone https://github.com/qd1332543/douyin-video-toolkit.git ~/.qclaw/skills/douyin-video-toolkit

# 重启 OpenClaw Gateway
openclaw gateway restart
```

### 前置依赖

- **ffmpeg**（需支持 libass）：`brew install ffmpeg`
- **OpenClaw** + **xbrowser skill**（用于浏览器自动化操作）

---

## 快速开始

在 OpenClaw 对话中直接说：

> 「帮我把昨晚的抖音直播回放下载下来」

或更具体的：

> 「下载这场直播回放，然后裁剪 1小时21分 附近的高光片段，做成竖屏短视频，加慢动作和字幕」

AI 会自动按照以下流程执行：

```
Step 1 → 直播回放下载（提取 M3U8 → ffmpeg codec copy）
Step 2 → 音频分析定位高光（静音检测 + 响度分析）
Step 3 → 片段剪辑（精确裁剪）
Step 4 → 竖屏转换（16:9 → 9:16，模糊背景填充）
Step 5 → 慢动作特效（tmix 帧混合，三段式拼接）
Step 6 → ASS 字幕烧录
Step 7 → BGM 混音（淡入淡出）
Step 8 → 浏览器自动发布到抖音创作者后台
```

---

## 脚本速查

所有脚本在 `scripts/` 目录，可直接命令行使用：

```bash
# 下载直播回放
./scripts/download_replay.sh "https://...m3u8" "我的直播"

# 提取片段
./scripts/extract_clip.sh source.mp4 01:21:40 01:22:40 clip.mp4

# 慢放 + 竖屏（三段式拼接）
./scripts/slowmo_vertical.sh clip.mp4 4 6.5 1.5 output.mp4

# 添加 BGM
./scripts/add_bgm.sh video.mp4 bgm.mp3 0.25 59 3.5 output.mp4
```

---

## 效果预览

| 处理前 | 处理后 |
|--------|--------|
| 横屏 1920×1080，111 分钟 | 竖屏 1080×1920，62 秒 |
| 无字幕，原声 | ASS 字幕 + BGM 混音 |
| 未剪辑，大量静音段 | 精准高光片段 + 慢动作 |

---

## 文件说明

```
douyin-video-toolkit/
├── SKILL.md                          # AI 工作流（让 AI 知道怎么执行）
├── README.md                         # 本文件
├── references/
│   ├── ffmpeg-cookbook.md            # 完整 ffmpeg 命令手册
│   ├── subtitles-guide.md            # ASS 字幕设计规范
│   ├── troubleshooting.md            # 11 个常见故障及解决方案
│   └── bgm-library.md               # 推荐 BGM 列表与下载源
└── scripts/
    ├── download_replay.sh            # M3U8 下载脚本
    ├── extract_clip.sh               # 片段裁剪脚本
    ├── slowmo_vertical.sh            # 慢放 + 竖屏一条龙
    └── add_bgm.sh                    # BGM 混音脚本
```

---

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| ffmpeg 被 SIGKILL | 拆分步骤，避免单条命令跑太久 |
| 字幕不显示 | `ffmpeg -filters \| grep ass` 检查 libass |
| 手机听不到 BGM | 避免低频重低音，BGM 音量 25-35% |
| macOS 无法打开文件 | `xattr -cr file.mp4` |
| 话题标签出现在视频里 | 用 drawbox 遮盖，不要裁剪视频 |

详见 [troubleshooting.md](references/troubleshooting.md)

---

## 示例：一条命令生成竖屏短视频

三段式慢放 + 竖屏 + 模糊背景：

```bash
./scripts/slowmo_vertical.sh clip_raw.mp4 4 6.5 1.5
```

- `4` — 慢放起始秒
- `6.5` — 慢放结束秒
- `1.5` — 慢放倍率

---

## License

MIT

---

## 致谢

- [FFmpeg](https://ffmpeg.org) — 视频处理核心
- 抖音创作者平台 — 内容来源
- OpenClaw — AI 自动化框架
