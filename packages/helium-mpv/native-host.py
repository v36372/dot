#!/usr/bin/python3
import json
import os
import struct
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlsplit

MPV = Path("/opt/homebrew/bin/mpv")
LOG = Path.home() / "Library" / "Logs" / "helium-mpv.log"
ALLOWED_HEADERS = ("authorization", "cookie", "origin")


def clean(value, limit=16_384):
    if not isinstance(value, str) or "\r" in value or "\n" in value:
        return ""
    return value[:limit]


def command_for(message):
    url = clean(message.get("url"), 32_768)
    parsed = urlsplit(url)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise ValueError("Only HTTP(S) stream URLs are allowed")
    if not MPV.is_file():
        raise FileNotFoundError("mpv is not installed at /opt/homebrew/bin/mpv")

    headers = message.get("headers") if isinstance(message.get("headers"), dict) else {}
    args = [str(MPV), "--no-terminal"]

    title = clean(message.get("title"), 512)
    referrer = clean(headers.get("referer") or message.get("pageUrl"), 8_192)
    user_agent = clean(headers.get("user-agent"), 2_048)
    if title:
        args.append("--force-media-title=" + title)
    if referrer:
        args.append("--referrer=" + referrer)
    if user_agent:
        args.append("--user-agent=" + user_agent)
    for name in ALLOWED_HEADERS:
        value = clean(headers.get(name))
        if value:
            args.append("--http-header-fields-append=" + name.title() + ": " + value)

    args.append(url)
    return args


def read_message():
    size_bytes = sys.stdin.buffer.read(4)
    if len(size_bytes) != 4:
        raise EOFError("No native message received")
    size = struct.unpack("=I", size_bytes)[0]
    if size > 64 * 1024 * 1024:
        raise ValueError("Native message is too large")
    payload = sys.stdin.buffer.read(size)
    if len(payload) != size:
        raise EOFError("Incomplete native message")
    return json.loads(payload.decode("utf-8"))


def write_message(message):
    payload = json.dumps(message, separators=(",", ":")).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("=I", len(payload)))
    sys.stdout.buffer.write(payload)
    sys.stdout.buffer.flush()


def self_test():
    args = command_for({
        "url": "https://media.example/live.m3u8?token=test",
        "title": "Test stream",
        "pageUrl": "https://example.test/watch",
        "headers": {"origin": "https://example.test", "cookie": "session=test"},
    })
    assert args[-1].startswith("https://media.example/")
    assert "--referrer=https://example.test/watch" in args
    assert "--http-header-fields-append=Cookie: session=test" in args
    print("native-host self-test: ok")


def main():
    try:
        message = read_message()
        args = command_for(message)
        LOG.parent.mkdir(parents=True, exist_ok=True)
        with LOG.open("ab") as log:
            process = subprocess.Popen(
                args,
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=log,
                start_new_session=True,
                close_fds=True,
            )
        write_message({"ok": True, "pid": process.pid})
    except Exception as error:
        write_message({"ok": False, "error": str(error)})


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
    else:
        main()
