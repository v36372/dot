# Play Stream in mpv for Helium

A local-only Chromium extension that detects HLS (`.m3u8`), DASH (`.mpd`),
and FLV streams requested by the current tab. Its popup sends the selected
stream and required request headers to a native messaging host, which launches
Homebrew mpv.

## Install

```bash
./install.sh
```

Then open `helium://extensions`, enable **Developer mode**, click
**Load unpacked**, and select the printed `extension/` directory.

## Use

1. Start the video in Helium.
2. Click **Play Stream in mpv** in the toolbar.
3. Select a detected stream and click **Play in mpv**.

The source tab is muted after mpv starts. Reload the page if no stream appears.

## Security and limits

- Broad site access is required to observe media requests and their Referer,
  Origin, and Cookie headers. Data stays on this Mac.
- The native host accepts messages only from this extension's fixed ID and
  only launches HTTP(S) URLs through `/opt/homebrew/bin/mpv` without a shell.
- This detects streams the browser already receives. It does not bypass DRM;
  Widevine-protected media will not play in mpv.
- Native host errors are logged to `~/Library/Logs/helium-mpv.log`.
