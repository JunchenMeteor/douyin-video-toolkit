# 抖音视频二创工具包

[English](README.md)

这是一个 OpenClaw skill 和 FFmpeg 工具包，用来把抖音直播回放素材处理成竖屏短视频。

它覆盖从回放获取到成片输出的常见流程：M3U8 回放下载、高光片段裁剪、9:16 竖屏转换、慢动作特效、ASS 字幕烧录、BGM 混音，以及抖音创作者中心的发布前准备。

重要说明：这个 skill 可以配合浏览器自动化完成上传前的准备工作，但必须停在最终发布之前。它可以打开抖音创作者中心、上传视频、填写草稿字段、等待平台检测，并汇报页面状态。它不能点击最终发布按钮。视频、标题、话题、可见性和平台检测结果都应该由创作者确认后再发布。

## 使用场景

- 下载你自己的，或你有权处理的抖音直播回放。
- 把游戏直播高光、翻车、反应片段剪成短视频。
- 把横屏回放转换成适合抖音的 1080x1920 竖屏视频。
- 用可复用的 FFmpeg 命令添加慢动作、字幕和背景音乐。
- 在抖音创作者中心准备视频草稿，等待人工最终确认。

## 前置依赖

- macOS、Linux 或 Windows PowerShell 环境。
- `ffmpeg` 和 `ffprobe`。
- `bc`，用于 Bash 慢动作脚本里的数值计算。
- FFmpeg 需要支持 `tmix`、`drawtext`、`afade` 等常用滤镜；如果要烧录 ASS 字幕，最好支持 `ass`/`subtitles`。
- 如果要让 Agent 辅助操作创作者中心，需要 OpenClaw 和类似 `xbrowser` 的浏览器自动化 skill。

检查本机环境：

```bash
./scripts/check_env.sh
```

Windows PowerShell：

```powershell
.\scripts\check_env.ps1
```

## 安装

### OpenClaw

```text
安装 douyin-video-toolkit skill
```

如果需要手动安装：

```bash
git clone https://github.com/JunchenMeteor/douyin-video-toolkit.git ~/.qclaw/skills/douyin-video-toolkit
openclaw gateway restart
```

### Codex

把这个仓库复制或克隆到 Codex skills 目录：

```bash
git clone https://github.com/JunchenMeteor/douyin-video-toolkit.git ~/.codex/skills/douyin-video-toolkit
```

需要时显式调用：

```text
Use $douyin-video-toolkit to process an authorized Douyin replay into a vertical short-video draft. Stop before final publish.
```

Codex UI 元数据在：

```text
agents/openai.yaml
```

### Claude Code

Claude Code 可以读取仓库级指引：

```text
CLAUDE.md
```

如果要在某个项目里使用，可以把 `CLAUDE.md` 里的内容复制或合并到目标项目的 `CLAUDE.md` 中。不要覆盖项目原有规则，建议作为一个简短章节追加。

如果你的 Claude Code 环境支持用户级 skills，也可以把仓库克隆到 Claude skills 目录：

```bash
git clone https://github.com/JunchenMeteor/douyin-video-toolkit.git ~/.claude/skills/douyin-video-toolkit
```

## 使用

### 快速开始

在 OpenClaw 中描述你想要的结果：

```text
帮我下载昨晚的抖音直播回放，裁剪 01:21:00 附近的高光片段，做成竖屏短视频，加慢动作和字幕，然后准备上传。
```

推荐流程：

```text
1. 提取或提供回放 M3U8 地址
2. 用 FFmpeg 流复制下载回放
3. 分析音频，辅助定位可能的高光片段
4. 裁剪选中的片段
5. 转成 9:16 竖屏视频
6. 添加慢动作特效
7. 按需烧录字幕
8. 按需混入 BGM
9. 准备上传页面，并停在最终发布前
```

### 发布边界

这个工具包可以帮助准备抖音创作者中心草稿：

- 打开创作者中心页面
- 上传渲染完成的视频
- 按用户要求填写标题、简介、话题、分类和可见性
- 等待平台检测完成
- 汇报哪些内容已准备好、哪些内容还需要确认

这个工具包不应该：

- 点击最终发布按钮
- 绕过账号、登录或平台限制
- 在用户未直接确认前发布内容
- 下载或复用用户无权处理的内容

### 脚本速查

所有脚本都在 `scripts/` 目录。

```bash
# 检查本机依赖
./scripts/check_env.sh

# 下载直播回放
./scripts/download_replay.sh "https://...m3u8" "my-live-replay"

# 提取片段
./scripts/extract_clip.sh source.mp4 01:21:40 01:22:40 clip.mp4

# 生成慢动作竖屏视频
./scripts/slowmo_vertical.sh clip.mp4 4 6.5 1.5 output.mp4

# 添加背景音乐
./scripts/add_bgm.sh video.mp4 bgm.mp3 0.25 59 3.5 output.mp4
```

Windows PowerShell 对应命令：

```powershell
# 检查本机依赖
.\scripts\check_env.ps1

# 下载直播回放
.\scripts\download_replay.ps1 -M3U8Url "https://...m3u8" -OutputName "my-live-replay"

# 提取片段
.\scripts\extract_clip.ps1 -InputVideo source.mp4 -StartTime 01:21:40 -EndTime 01:22:40 -Output clip.mp4

# 生成慢动作竖屏视频
.\scripts\slowmo_vertical.ps1 -InputVideo clip.mp4 -SlowStart 4 -SlowEnd 6.5 -SlomoFactor 1.5 -Output output.mp4

# 添加背景音乐
.\scripts\add_bgm.ps1 -Video video.mp4 -Bgm bgm.mp3 -Volume 0.25 -FadeStart 59 -FadeDuration 3.5 -Output output.mp4
```

## 效果示例

| 处理前 | 处理后 |
| --- | --- |
| 1920x1080 横屏回放 | 1080x1920 竖屏短视频 |
| 很长且包含静音段的回放 | 聚焦高光片段 |
| 只有原声 | 字幕和可选 BGM |
| 正常播放 | 可选三段式慢动作片段 |

## 仓库结构

```text
douyin-video-toolkit/
├── agents/
│   └── openai.yaml
├── CLAUDE.md
├── SKILL.md
├── README.md
├── README.zh-CN.md
├── LICENSE
├── references/
│   ├── ffmpeg-cookbook.md
│   ├── subtitles-guide.md
│   ├── troubleshooting.md
│   └── bgm-library.md
└── scripts/
    ├── check_env.sh
    ├── check_env.ps1
    ├── download_replay.sh
    ├── download_replay.ps1
    ├── extract_clip.sh
    ├── extract_clip.ps1
    ├── slowmo_vertical.sh
    ├── slowmo_vertical.ps1
    ├── add_bgm.sh
    └── add_bgm.ps1
```

## 安全和合规

- 只下载、剪辑和上传你拥有版权或明确获得授权的内容。
- 使用你自己的账号，通过正常的抖音创作者中心流程操作。不要绕过登录、付费墙、访问控制、频率限制或反滥用机制。
- 把回放 M3U8 地址视为临时私有访问链接。不要公开、提交到代码仓库，也不要分享包含这些链接的日志。
- BGM 默认优先使用抖音平台自己的音乐库或创作者中心可选音乐。如果使用外部音频文件，用户必须已经拥有使用权。
- 平台内可用音乐也可能受地区、账号类型或商业化场景限制；发布前请以平台提示为准。
- 不要移除创作者水印、版权声明或署名标记，除非你拥有该内容且有正当理由。
- 不要用这个工具包冒充其他创作者、搬运未授权视频或规避平台审核。
- 最终发布应保留为人工确认动作。
- 如果不确定授权边界，先保留为本地草稿，确认权利后再上传。

## 参考文档

- [FFmpeg 命令手册](references/ffmpeg-cookbook.md)
- [字幕制作指南](references/subtitles-guide.md)
- [故障排除](references/troubleshooting.md)
- [BGM 资源库](references/bgm-library.md)
- [Claude Code 指引](CLAUDE.md)

## 许可证

MIT
