# BGM 资源库

推荐用于抖音游戏搞笑视频的 BGM 列表和下载源。

---

## 推荐 BGM

### 游戏搞笑/翻车

| 曲名 | 作者 | 风格 | 来源 | 时长 |
|------|------|------|------|------|
| 猪突猛進 | 百石元 | 搞笑/轻松/中二 | 汽水音乐 | ~90s |
| Fluffing a Duck | Kevin MacLeod | 滑稽/轻快 | YouTube Audio Library | ~60s |
| Monkeys Spinning Monkeys | Kevin MacLeod | 欢快/搞笑 | YouTube Audio Library | ~2min |
| Scheming Weasel | Kevin MacLeod | 狡黠/快节奏 | YouTube Audio Library | ~1min |

### 动作/战斗高光

| 曲名 | 来源 | 风格 |
|------|------|------|
| 進撃の巨人 OST | 动漫 | 燃/史诗 |
| Unravel (Tokyo Ghoul) | 动漫 | 燃/悲伤 |
| 各种 BOSS 战 BGM | 魔兽世界 OST | 史诗/战斗 |

---

## 下载源

### 抖音生态内（推荐，无版权风险）

1. 抖音搜索：搜索"搞笑游戏BGM"找推荐视频
2. 汽水音乐：抖音视频左下角"汽水音乐"链接
3. 直接下载链接通常有时效性，需要实时抓取

### 开源/免费音乐库

| 平台 | URL | 特点 |
|------|-----|------|
| YouTube Audio Library | youtube.com/audiolibrary | 完全免费，可商用 |
| Pixabay Music | pixabay.com/music | 免费可商用，但有 Cloudflare 防护 |
| Freesound | freesound.org | CC 协议，质量参差 |
| 甘茶の音楽工房 | amachamusic.chagasi.com | 日系音乐，免费用 |

### 技术方案

1. **yt-dlp**（如 Python 环境可用）：
```bash
yt-dlp -x --audio-format mp3 --audio-quality 320K "URL"
```

2. **直接 curl 下载**（直链有效期内）：
```bash
curl -L -o bgm.mp3 "DIRECT_URL"
```

3. **录屏提取**（最后手段，质量损失大）

---

## BGM 选择原则

1. **抖音生态优先**：汽水音乐/抖音热门BGM 无版权风险
2. **避免人声**：纯器乐/电子，不抢话语
3. **高频突出**：手机扬声器可听范围
4. **情绪匹配**：搞笑场景用轻快/滑稽，战斗场景用燃/史诗
5. **320kbps MP3 足够**：手机播放不需要无损

---

## 处理技巧

1. **截取高潮段**：
```bash
ffmpeg -i bgm.mp3 -ss 10 -t 60 bgm_clip.mp3
```

2. **调整音量**：
```bash
ffmpeg -i bgm.mp3 -af "volume=0.3" bgm_quiet.mp3
```

3. **添加淡入淡出**：
```bash
ffmpeg -i bgm.mp3 -af "afade=t=in:d=1.5,afade=t=out:st=58.5:d=3.5" bgm_fade.mp3
```
