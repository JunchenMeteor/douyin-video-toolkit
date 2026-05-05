# 故障排除

常见问题和详细解决方案。

---

## 1. ffmpeg 进程被 SIGKILL/SIGTERM

**症状**：ffmpeg 运行一段时间后被强制终止，没有错误日志。

**原因**：
- macOS 系统资源限制（launchd 内存压力）
- 长时间编码超出系统容忍度
- 非系统资源耗尽（磁盘/CPU 正常但进程被 kill）

**解决方案**：
1. 拆分长流程为多个短步骤，避免单条命令超长编码
2. 减少 filter_complex 复杂度
3. 使用 `-preset ultrafast` 降低 CPU 内存占用
4. 清理临时文件后重启
5. 分步渲染：慢放 → 字幕 → 竖屏 → BGM，每步一条命令

---

## 2. sharp 模块无法加载（darwin-x64）

**症状**：
```
Error: Could not load the "sharp" module using the darwin-x64 runtime
```

**原因**：sharp 原生模块预编译为 arm64，x64 模拟不可用。

**解决方案**：
1. 使用 ffmpeg 替代进行截图/缩略图操作
2. 用 macOS 的 `sips` 命令处理图片
3. 如必须用 sharp，切换 Rosetta 前执行：
```bash
npm install --os=darwin --cpu=x64 sharp
```

---

## 3. libass 不可用

**症状**：`ass` 或 `subtitles` filter 不存在：
```
No such filter: 'ass'
```

**原因**：Homebrew 安装的 ffmpeg 未编译 libass 支持。

**解决方案**：
1. 检查当前 ffmpeg 的 filter 列表：
```bash
ffmpeg -filters 2>&1 | grep ass
```
2. 如果不存在：
```bash
brew uninstall ffmpeg
brew install ffmpeg
```
3. 验证：
```bash
ffmpeg -version | grep libass
# 期望：--enable-libass
```

> ⚠️ 不要轻易重装 ffmpeg！先确认当前版本的能力，可能只是版本号升级（8.1_1 → 8.1.1）反而丢失了 libass。

---

## 4. 字幕烧录不显示

**症状**：视频生成后看不到字幕文字。

**排查流程**：
1. 确认 ffmpeg 支持 libass：`ffmpeg -filters 2>&1 | grep ass`
2. 确认 ASS 文件编码：`file -I subtitles.ass`（必须 UTF-8）
3. 确认 ASS 分辨率与实际视频匹配
4. 测试最简单字幕：
```bash
ffmpeg -i test.mp4 -vf "drawtext=text='TEST':fontsize=48:fontcolor=red:x=100:y=100" out.mp4
```
5. 如果 drawtext 可显示，说明问题在 ASS 滤镜

---

## 5. 画面底部出现不想要的内容（话题标签）

**症状**：视频底部的 #话题 标签出现在最终画面中。

**解决方案**：

方案 A（推荐）：`drawbox` 遮盖
```bash
ffmpeg -i input.mp4 -vf \
  "drawbox=x=0:y=ih-200:w=iw:h=200:color=black@1.0:t=fill" \
  -c:v libx264 -preset fast output.mp4
```

方案 B（不推荐）：裁剪末尾
```bash
ffmpeg -i input.mp4 -t 58.5 -c copy output.mp4
```
⚠️ 会丢失画面内容（如角色死亡画面）

---

## 6. macOS quarantine 标记

**症状**：从网络下载的文件无法打开，提示"无法验证开发者"。

**解决方案**：
```bash
xattr -cr file.mp4
# 或
xattr -d com.apple.quarantine file.mp4
```

---

## 7. BGM 混音后原声被压住

**症状**：混入 BGM 后原声几乎听不见。

**原因**：`amix` 默认均分音量，inputs=2 时每个输入减半。

**解决方案**：
使用 `weights` 参数控制混音比例：
```bash
[0:a][bgm]amix=inputs=2:duration=first:weights=1 0.3
```
- 原声权重 1
- BGM 权重 0.3（先用 `volume=0.25` 再乘以 0.3）

---

## 8. 手机端 BGM 听不见

**症状**：电脑上 BGM 正常，手机上完全听不到。

**原因**：BGM 低频太重，手机扬声器截止频率约 200Hz。

**解决方案**：
1. 用高频突出的 BGM（弦乐、电子音、打击乐）
2. 避免重低音（55Hz 以下人耳也听不见，手机更放不出）
3. 提高 BGM 音量到 30-40%：`volume=0.35`
4. 使用 `equalizer` 削减低频：
```bash
[1:a]equalizer=f=100:t=q:w=1:g=-12,volume=0.3[bgm]
```

---

## 9. 视频偏色/绿屏

**症状**：片段提取后颜色偏绿或偏粉。

**原因**：H.265 10-bit 色深转码时的色彩空间问题。

**解决方案**：
```bash
ffmpeg -i input.mp4 -vf "scale=out_color_matrix=bt709" -c:v libx264 output.mp4
```

---

## 10. 上传抖音后画质变差

**原因**：抖音会重新转码。可通过以下方式减少损失：

1. 输出 H.264 + AAC（最兼容）
2. 码率不低于 8Mbps：`-b:v 8M`
3. CRF ≤ 20：`-crf 18`（虽然文件大）
4. 分辨率精确匹配 1080×1920

---

## 11. FFmpeg 版本回退

如果新版 ffmpeg 缺少功能（如 libass），回退到已知可用版本：

```bash
# 查看可用版本
brew search ffmpeg

# 安装特定版本（如有）
brew install ffmpeg@6

# 或从源码编译指定版本（复杂，不展开）
```
