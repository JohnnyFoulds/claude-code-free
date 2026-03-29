#!/usr/bin/env python3
"""Convert asciinema v3 cast (relative timestamps) to v2 (absolute timestamps).

Usage:
    python3 cast-v3-to-v2.py input.cast output.cast

asciinema 3.x records in v3 format where event timestamps are relative to the
previous event. svg-term and agg both require v2 format where timestamps are
absolute (seconds since recording start). This script performs the conversion.
"""

import json
import sys


def convert(src: str, dst: str) -> None:
    with open(src) as f:
        raw = f.read().strip().splitlines()

    header_v3 = json.loads(raw[0])
    term = header_v3.get("term", {})

    header_v2 = {
        "version": 2,
        "width": term.get("cols", 110),
        "height": term.get("rows", 30),
        "timestamp": header_v3.get("timestamp"),
        "title": header_v3.get("title", ""),
        "env": {"TERM": "xterm-256color", "SHELL": "/bin/bash"},
    }

    events = []
    abs_time = 0.0
    for line in raw[1:]:
        line = line.strip()
        if not line:
            continue
        e = json.loads(line)
        # v3: [relative_offset, type, data]
        # v2: [absolute_time, type, data]
        abs_time += float(e[0])
        events.append([round(abs_time, 6), e[1], e[2]])

    with open(dst, "w") as f:
        f.write(json.dumps(header_v2) + "\n")
        for ev in events:
            f.write(json.dumps(ev) + "\n")

    print(f"Converted {len(events)} events, total duration {abs_time:.1f}s")
    print(f"Output: {dst}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} input.cast output.cast")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
