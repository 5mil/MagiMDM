#!/usr/bin/env python3
"""Laptop agent stand-in for console testing."""
import json, os, time, urllib.request

URL = os.environ.get("MDM_URL", "http://127.0.0.1:8788")
TOKEN = os.environ.get("TOKEN", "dev")
PLATFORM = os.environ.get("PLATFORM", "linux")
SLUG = os.environ.get("IMAGE_SLUG", "linux-debian12-student")

def post(path, body):
    req = urllib.request.Request(
        URL + path,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.load(r)

def main():
    enroll = post(
        "/api/agent/enroll",
        {
            "token": TOKEN,
            "name": os.uname().nodename,
            "platform": PLATFORM,
            "os_version": "mock",
            "agent_version": "0.1.0-mock",
            "image_slug": SLUG,
        },
    )
    uuid = enroll.get("uuid") or enroll.get("device_uuid")
    print("enrolled", uuid)
    while True:
        try:
            poll = post(
                "/api/agent/poll",
                {"uuid": uuid, "agent_version": "0.1.0-mock", "extras": {"image": SLUG}},
            )
            print("poll", poll)
        except Exception as e:
            print("poll err", e)
        time.sleep(60)

if __name__ == "__main__":
    main()
