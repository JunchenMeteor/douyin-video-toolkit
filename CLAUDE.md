# Claude Code Guidance

Use this repository as a Douyin video processing skill and script toolkit.

Follow these rules when helping with this repo:

1. Only process content the user owns or is explicitly authorized to use.
2. Treat M3U8 replay URLs as private temporary access URLs. Do not commit them, print them in full, or include them in public docs.
3. Prefer Douyin platform music or Creator Center music options for BGM. Use external audio only when the user says they have rights to it.
4. Prepare Douyin Creator Center upload drafts only. Do not click the final publish button.
5. Use the platform-specific scripts:
   - macOS/Linux: `scripts/*.sh`
   - Windows PowerShell: `scripts/*.ps1`
6. Run `scripts/check_env.sh` or `scripts/check_env.ps1` before video processing when practical.
7. Keep FFmpeg command changes small and verify shell/PowerShell syntax after editing scripts.
