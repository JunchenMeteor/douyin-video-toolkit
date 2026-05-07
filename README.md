# Douyin Video Toolkit

[简体中文](README.zh-CN.md)

An OpenClaw skill and FFmpeg toolkit for turning Douyin live replay footage into short vertical videos.

The toolkit covers the practical workflow from replay capture to edited output: M3U8 replay download, highlight clipping, 9:16 vertical conversion, slow-motion effects, ASS subtitle burn-in, BGM mixing, and preparation for upload in Douyin Creator Center.

Important: the skill can automate upload preparation with browser automation, but it must stop before the final publish action. It can open Douyin Creator Center, upload the video, fill draft fields, wait for platform checks, and report the page state. It must not click the final publish button. The creator should review the video, title, tags, visibility, and checks before publishing.

## Use Cases

- Download a Douyin live replay that belongs to you or that you are authorized to process.
- Cut gaming livestream highlights, fails, or reaction moments into short videos.
- Convert landscape replay footage into Douyin-friendly 1080x1920 vertical output.
- Add slow motion, subtitles, and background music using repeatable FFmpeg commands.
- Prepare a video draft in Douyin Creator Center for final human review.

## Requirements

- macOS, Linux, or Windows PowerShell environment.
- `ffmpeg` and `ffprobe`.
- `bc` for numeric calculations in the Bash slow-motion script.
- FFmpeg with useful filters such as `tmix`, `drawtext`, `afade`, and preferably `ass`/`subtitles` for ASS subtitle burn-in.
- OpenClaw with an `xbrowser`-style browser automation skill if you want agent-assisted Creator Center preparation.

Run the environment check:

```bash
./scripts/check_env.sh
```

On Windows PowerShell:

```powershell
.\scripts\check_env.ps1
```

## Installation

### OpenClaw

```text
Install the douyin-video-toolkit skill
```

If you prefer manual installation:

```bash
git clone https://github.com/JunchenMeteor/douyin-video-toolkit.git ~/.qclaw/skills/douyin-video-toolkit
openclaw gateway restart
```

### Codex

Clone this repository into your Codex skills directory:

```bash
git clone https://github.com/JunchenMeteor/douyin-video-toolkit.git ~/.codex/skills/douyin-video-toolkit
```

Then invoke it explicitly when needed:

```text
Use $douyin-video-toolkit to process an authorized Douyin replay into a vertical short-video draft. Stop before final publish.
```

The Codex UI metadata lives in:

```text
agents/openai.yaml
```

### Claude Code

Use the repository-level guidance in:

```text
CLAUDE.md
```

For a project, copy or merge the `CLAUDE.md` guidance into that project's `CLAUDE.md` file. Keep any existing project-specific instructions and add this toolkit guidance as a short section.

If your Claude Code setup supports user-level skills, clone this repository into your Claude skills directory:

```bash
git clone https://github.com/JunchenMeteor/douyin-video-toolkit.git ~/.claude/skills/douyin-video-toolkit
```

## Usage

### Quick Start

In OpenClaw, ask for a concrete outcome:

```text
Download my Douyin live replay from last night, cut the highlight around 01:21:00, convert it to a vertical short video, add slow motion and subtitles, then prepare it for upload.
```

The intended workflow is:

```text
1. Extract or provide the replay M3U8 URL
2. Download the replay with FFmpeg stream copy
3. Analyze audio to locate likely highlights
4. Cut the selected clip
5. Convert the clip to 9:16 vertical video
6. Add slow-motion effects
7. Burn subtitles if needed
8. Mix BGM if provided
9. Prepare the upload page and stop before final publish
```

### Publishing Boundary

This toolkit can help prepare a Douyin Creator Center draft:

- open the Creator Center page
- upload the rendered video
- fill title, description, tags, category, and visibility fields according to the user's instructions
- wait for platform checks to finish
- report what is ready and what still needs review

This toolkit should not:

- click the final publish button
- bypass account, login, or platform controls
- publish without the user's direct review
- download or reuse content the user is not authorized to process

### Script Reference

All scripts live in `scripts/`.

```bash
# Check local dependencies
./scripts/check_env.sh

# Download a live replay from an M3U8 URL
./scripts/download_replay.sh "https://...m3u8" "my-live-replay"

# Extract a clip
./scripts/extract_clip.sh source.mp4 01:21:40 01:22:40 clip.mp4

# Create a slow-motion vertical video
./scripts/slowmo_vertical.sh clip.mp4 4 6.5 1.5 output.mp4

# Add background music
./scripts/add_bgm.sh video.mp4 bgm.mp3 0.25 59 3.5 output.mp4
```

Windows PowerShell equivalents:

```powershell
# Check local dependencies
.\scripts\check_env.ps1

# Download a live replay from an M3U8 URL
.\scripts\download_replay.ps1 -M3U8Url "https://...m3u8" -OutputName "my-live-replay"

# Extract a clip
.\scripts\extract_clip.ps1 -InputVideo source.mp4 -StartTime 01:21:40 -EndTime 01:22:40 -Output clip.mp4

# Create a slow-motion vertical video
.\scripts\slowmo_vertical.ps1 -InputVideo clip.mp4 -SlowStart 4 -SlowEnd 6.5 -SlomoFactor 1.5 -Output output.mp4

# Add background music
.\scripts\add_bgm.ps1 -Video video.mp4 -Bgm bgm.mp3 -Volume 0.25 -FadeStart 59 -FadeDuration 3.5 -Output output.mp4
```

## Output Example

| Before | After |
| --- | --- |
| 1920x1080 landscape replay | 1080x1920 vertical short video |
| Long replay with quiet sections | Focused highlight clip |
| Raw audio only | Subtitles and optional BGM |
| Normal playback | Optional three-part slow-motion segment |

## Repository Layout

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

## Safety and Compliance

- Only download, edit, and upload content you own or have explicit permission to use.
- Use Douyin Creator Center with your own account and normal platform access. Do not bypass login, paywalls, access controls, rate limits, or anti-abuse systems.
- Treat replay M3U8 URLs as temporary private access URLs. Do not publish them, commit them, or share logs that contain them.
- Prefer BGM from Douyin's own music library or Creator Center music options. If an external audio file is used, the user must already have the right to use it.
- Platform-available music can still have usage limits by region, account type, or monetization context; review the platform notice before publishing.
- Do not remove creator watermarks, copyright notices, or attribution marks unless you own the content and have a legitimate reason.
- Do not use the toolkit to impersonate other creators, repost unauthorized videos, or evade moderation.
- Keep final publishing as a human-confirmed action.
- When in doubt, keep the output as a local draft and verify rights before upload.

## References

- [FFmpeg cookbook](references/ffmpeg-cookbook.md)
- [Subtitle guide](references/subtitles-guide.md)
- [Troubleshooting](references/troubleshooting.md)
- [BGM library](references/bgm-library.md)
- [Claude Code guidance](CLAUDE.md)

## License

MIT
