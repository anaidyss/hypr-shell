#!/usr/bin/env python3
"""Search DuckDuckGo Images for full-size wallpapers (stdlib only).

Prints one `thumbnail_url|full_url` pair per line, filtering to images that
are at least 1920x1080. Pauses and stops are obeyed via a small control file.

Usage: hs-ddglink.py <query>
"""
import http.cookiejar
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

RUN_DIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "hypr-shell", "wallsearch")
CONTROL = os.path.join(RUN_DIR, "control")
PAUSE_TIMEOUT = 600
MIN_W, MIN_H = 1920, 1080

_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
}


def state():
    try:
        with open(CONTROL) as f:
            return f.read().strip()
    except OSError:
        return "run"


def wait_if_paused():
    paused_at = time.monotonic()
    while state() == "pause":
        if time.monotonic() - paused_at >= PAUSE_TIMEOUT:
            raise SystemExit(0)
        time.sleep(1)


def fetch(url, headers, timeout=10):
    req = urllib.request.Request(url, headers=headers)
    return urllib.request.urlopen(req, timeout=timeout)


def main():
    if len(sys.argv) < 2:
        return
    query = sys.argv[1].strip() + " wallpaper"

    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
    urllib.request.install_opener(opener)

    html_url = "https://duckduckgo.com/?" + urllib.parse.urlencode(
        {"q": query, "iar": "images", "iax": "images", "ia": "images"})

    vqd = None
    headers = dict(_HEADERS)
    headers["Referer"] = "https://duckduckgo.com/"
    for _ in range(3):
        try:
            html = fetch(html_url, headers).read().decode("utf-8")
            m = re.search(r"vqd=([0-9a-zA-Z_-]+)", html) or \
                re.search(r"vqd['\"]?\s*:\s*['\"]?([0-9a-zA-Z_-]+)", html)
            if m:
                vqd = m.group(1)
                break
        except Exception:
            time.sleep(1)
    if not vqd:
        return

    headers["Referer"] = html_url
    headers["Accept"] = "application/json, text/javascript, */*; q=0.01"

    next_url = None
    seen = set()
    for _ in range(5):
        if state() == "stop":
            break
        wait_if_paused()

        if next_url:
            url = "https://duckduckgo.com" + next_url
            if "vqd=" not in url:
                url += f"&vqd={vqd}"
        else:
            params = {
                "l": "us-en", "o": "json", "q": query, "vqd": vqd,
                "f": ",,,", "p": "1", "ex": "-1",
            }
            url = "https://duckduckgo.com/i.js?" + urllib.parse.urlencode(params)

        try:
            data = json.loads(fetch(url, headers).read().decode("utf-8"))
            for res in data.get("results", []):
                if state() == "stop":
                    return
                wait_if_paused()
                if int(res.get("width", 0)) >= MIN_W and int(res.get("height", 0)) >= MIN_H:
                    thumb, image = res.get("thumbnail"), res.get("image")
                    if thumb and image and image not in seen:
                        seen.add(image)
                        sys.stdout.write(f"{thumb}|{image}\n")
                        sys.stdout.flush()
            next_url = data.get("next")
            if not next_url:
                break
        except BrokenPipeError:
            os._exit(0)
        except Exception:
            break


if __name__ == "__main__":
    try:
        main()
        sys.stdout.flush()
    except SystemExit:
        raise
    except BaseException:
        os._exit(1)