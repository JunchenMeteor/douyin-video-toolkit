# 字幕制作指南

ASS 字幕格式说明和设计规范，用于游戏直播高光视频的二次创作。

## ASS 文件结构

```ass
[Script Info]
Title: 熔火之心 - 被弹飞进岩浆
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 2
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Title,PingFang SC,72,&H00FFFFFF&,&H000000FF&,&H00000000&,&H80000000&,1,0,0,0,100,100,0,0,1,3,0,2,20,20,50,1
Style: Action,PingFang SC,56,&H000000FF&,&H0000FFFF&,&H00000000&,&H80000000&,1,0,0,0,100,100,0,0,1,3,0,2,20,20,30,1
Style: Comment,PingFang SC,40,&H00FFFFFF&,&H000000FF&,&H00000000&,&H80000000&,0,0,0,0,100,100,0,0,1,2,0,2,20,20,20,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.20,0:00:03.50,Title,,0,0,0,,{\an5}{\pos(540,960)}被弹飞进岩浆！
Dialogue: 0,0:00:05.50,0:00:09.50,Action,,0,0,0,,{\an5}{\pos(540,1200)}💀 被弹飞！
Dialogue: 0,0:00:10.00,0:00:13.50,Comment,,0,0,0,,{\an2}{\pos(540,1800)}怎么会这样...
Dialogue: 0,0:00:58.50,0:00:62.50,Comment,,0,0,0,,{\an6}{\pos(540,1850)}#魔兽世界 #翻车现场
```

## 样式设计规范

### 设计原则

1. **标题字幕** (Title)：最大字号，白色，用于事件描述
2. **动作字幕** (Action)：中号，亮色/红色，用于高光瞬间
3. **吐槽字幕** (Comment)：小号，白色/灰色，跟随画面
4. **话题标签**：放在 ASS 中而非画面底部，避免使用 drawbox 遮盖需求

### 颜色编码 (ARGB 十六进制)

```
&H AABBGGRR &
   AA = Alpha (00=透明, 80=半透明, FF=不透明)
   BB = Blue
   GG = Green
   RR = Red
```

常用：
- `&H00FFFFFF&`：不透明白色
- `&H000000FF&`：不透明红色
- `&H0000FFFF&`：不透明黄色
- `&H80000000&`：半透明黑色（阴影/背景）

### 定位控制

`\an` 对齐方式：
- `\an5`：居中（推荐用于标题）
- `\an2`：底部居中
- `\an6`：底部居中
- `\an8`：顶部居中

`\pos(x,y)` 精确定位。

### 分辨率

`PlayResX: 1080` `PlayResY: 1920`：匹配竖屏分辨率。

## 字幕时机指南

### 高光视频（~60秒）典型字幕布局

| 时间段 | 字幕类型 | 位置 | 内容 |
|--------|----------|------|------|
| 0-3秒 | 标题引入 | 中间偏上 | 一句话概括事件 |
| 4-10秒 | 动作字幕 | 关键画面位置 | 强调动作/死亡/击杀 |
| 10-55秒 | 吐槽/解说 | 底部 | 跟随角色反应 |
| 58-62秒 | 话题标签 | 底部 | #标签 |

### 避免的问题

1. **话题标签不要出现在画面可裁剪范围** — 如果话题在 ASS 中，用 drawbox 遮不住
  - 解决方案：话题不放进 ASS，或者确认画面底部有 200px 安全区
2. **字幕不要太长** — 手机屏幕小，每行不超过 20 字
3. **时间不要太短** — ≤1.5s 的字幕用户看不清
4. **颜色不要太淡** — 手机亮度低时看不清

## 中文字体选择

macOS 可用中文字体（需完整路径或 fontconfig 配置）：

```
/System/Library/Fonts/PingFang.ttc      — 苹方（推荐）
/System/Library/Fonts/Hiragino Sans GB.ttc — 冬青黑体
/System/Library/Fonts/STHeiti Light.ttc  — 华文黑体
```

## 常见错误

1. **字幕不显示** → ffmpeg 无 libass 支持 → 改用 drawtext 或重装 ffmpeg
2. **字幕位置错乱** → ASS PlayResX/Y 与实际分辨率不匹配
3. **中文乱码** → ASS 文件编码必须为 UTF-8
4. **字幕闪烁** → Outline/Shadow 太小 → 增大到 Outline≥2, Shadow≥0
