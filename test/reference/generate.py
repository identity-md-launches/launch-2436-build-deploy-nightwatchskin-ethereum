#!/usr/bin/env python3
"""Independent, standard-library SVG oracle and reproducible Solidity test corpus.

Run `python3 test/reference/generate.py --check` to verify the committed corpus,
or omit --check to regenerate it. `cast keccak` supplies Ethereum Keccak-256;
Python's SHA3-256 is deliberately not used for SVG hashes. No network is used.
"""

import argparse
import hashlib
from pathlib import Path
import subprocess


COLOURS = ("#3FE6FF", "#B8FF4A", "#A98BFF", "#FF4FD8", "#FFC46B", "#E9E4FF")
KNOWN = (
    (1, 1, [184, 185, 186, 189, 190, 78, 80, 81, 82, 86],
     "0x2a93428c834d0f406f41844fbd93691276402298a395e0462c27cf41a6634e4c"),
    (7, 3, [26, 30, 50, 2, 5, 96, 97, 93, 94, 87],
     "0xaaf9e3a1dd4ce02bdfe8a864f16037c4c574974d1fe5e852b78ac8c6ba0477e0"),
    (50, 5, [10, 45, 103, 12, 19, 22, 69, 188, 204, 267],
     "0xb2e57d5de55080f34fe0d6818af8d64f27b6850b3c2bd9fe18ad19682b55fb8f"),
    (0, 6, [1, 45, 103, 12, 19, 22, 69, 188, 204, 267],
     "0xeecaf052aaad318dfead6dc6ca66725156009b16cd331563b85b5cc64b060b53"),
)


def render(n, t, inputs):
    if not 0 <= n <= 9999 or not 1 <= t <= 6:
        raise ValueError("invalid number or tier")
    if len(inputs) != 10 or any(not 0 <= v <= 65535 for v in inputs):
        raise ValueError("expected ten uint16 identifiers")
    c = COLOURS[t - 1]
    result = [
        f'<defs><pattern id="nwS" width="8" height="6" patternUnits="userSpaceOnUse"><path d="M0 .5H8" stroke="#E2E8F0" stroke-opacity=".08"/></pattern><linearGradient id="nwB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c}" stop-opacity="0"/><stop offset="1" stop-color="{c}" stop-opacity=".28"/></linearGradient><linearGradient id="nwE" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c}"/><stop offset=".55" stop-color="#A3E635"/><stop offset="1" stop-color="#8B5CF6"/></linearGradient></defs>',
        '<rect width="1000" height="1000" fill="url(#nwS)"><animateTransform attributeName="transform" type="translate" values="0 0;0 6" dur="1s" repeatCount="indefinite"/></rect>',
    ]
    if t >= 2:
        result.append(f'<rect x="24" y="-80" width="952" height="80" fill="url(#nwB)"><animate attributeName="y" values="-80;976" dur="{9-t}s" repeatCount="indefinite"/></rect>')
    for k in range(16):
        h = 8 + inputs[k % 10] * (k + 7) % 41
        result.append(f'<rect x="{588+14*k}" y="{142-h}" width="6" height="{h}" fill="currentColor" opacity=".55"><animate attributeName="opacity" values=".55;1;.25;.55" dur="{2+k%4}s" begin="{125*k}ms" repeatCount="indefinite"/></rect>')
    tag = "THE CAPTAIN" if t == 6 else "ON WATCH"
    result.append(f'<rect x="66" y="188" width="8" height="12" fill="currentColor"><animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/></rect><text x="82" y="199" font-size="12" font-family="monospace" fill="#C4B4FF" letter-spacing="3">ID / #{n:04d} / {tag}</text>')
    orbits = []
    if t >= 2:
        orbits.append((-12, "0;1", 16 - 2*t))
    if t >= 5:
        orbits.append((14, "1;0", 16 - 2*t))
    if t == 6:
        orbits.append((38, "0;1", 6))
    for rotation, keys, duration in orbits:
        result.append(f'<g transform="rotate({rotation} 500 520)" opacity=".8"><ellipse cx="500" cy="520" rx="430" ry="96" fill="none" stroke="currentColor" stroke-width="2.5" stroke-dasharray="4 8"/><circle r="6" fill="#F2EFFF"><animateMotion dur="{duration}s" repeatCount="indefinite" keyPoints="{keys}" keyTimes="0;1" calcMode="linear" path="M70 520a430 96 0 1 0 860 0a430 96 0 1 0 -860 0"/></circle></g>')
    if t >= 3:
        for k in range(6):
            x, anchor = (40, "start") if k < 3 else (930, "end")
            row = ":".join(f"{inputs[j % 10]:03x}" for j in range(3*k, 3*k+3))
            result.append(f'<text x="{x}" y="{300+18*(k%3)}" font-size="11" font-family="monospace" fill="currentColor" text-anchor="{anchor}" opacity=".5">{row}<animate attributeName="opacity" values=".2;.75;.2" dur="{3+k}s" repeatCount="indefinite"/></text>')
    for k in range(8):
        x = (40 if k % 2 == 0 else 836) + (37*n + 53*k) % 120
        y = 230 + (61*n + 97*k) % 560
        result.append(f'<rect x="{x}" y="{y}" width="3" height="3" fill="#E2E8F0"><animate attributeName="opacity" values=".1;.8;.1" dur="{2+(n+k)%3}s" repeatCount="indefinite"/></rect>')
    if t >= 4:
        result.append(f'<path d="M60 24H940L976 60V940L940 976H60L24 940V60Z" fill="none" stroke="url(#nwE)" stroke-width="5" stroke-dasharray="60 30"><animate attributeName="stroke-dashoffset" values="0;-900" dur="{12-t}s" repeatCount="indefinite"/></path>')
    return "".join(result)


def keccak(value):
    return subprocess.check_output(["cast", "keccak", value], text=True).strip()


def corpus():
    for t in range(1, 7):
        yield 0, t, [0]*10
        yield 9999, t, [65535]*10
    boundary = [0, 1, 15, 16, 255, 256, 4095, 4096, 65534, 65535]
    for n in (9, 10, 99, 100, 999, 1000):
        yield n, 3, boundary
    for i in range(36):
        inputs = [int.from_bytes(hashlib.sha256(f"NightWatchSkin/{i}/{j}".encode()).digest()[:2], "big")
                  for j in range(10)]
        yield (i*761 + 43) % 10000, i % 6 + 1, inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for n, t, inputs, expected in KNOWN:
        actual = keccak(render(n, t, inputs))
        if actual != expected:
            raise AssertionError(f"supplied vector ({n}, {t}): {actual} != {expected}")
    vectors = list(corpus())
    lines = [
        "// SPDX-License-Identifier: MIT", "pragma solidity 0.8.26;", "",
        "// Generated by test/reference/generate.py; do not edit by hand.",
        "library ReferenceVectors {",
        f"    uint256 internal constant COUNT = {len(vectors)};", "",
        "    function get(uint256 index) internal pure returns (uint256, uint8, uint16[10] memory, bytes32) {",
    ]
    for index, (n, t, inputs) in enumerate(vectors):
        array = ", ".join([f"uint16({inputs[0]})"] + [str(v) for v in inputs[1:]])
        lines.append(f"        if (index == {index}) return ({n}, {t}, [{array}], {keccak(render(n, t, inputs))});")
    lines.extend(['        revert("reference vector out of range");', "    }", "}", ""])
    # Let the same formatter used on the project produce the committed representation.
    generated = subprocess.check_output(["forge", "fmt", "--raw", "-"], input="\n".join(lines), text=True)
    destination = Path(__file__).resolve().parents[1] / "fixtures" / "ReferenceVectors.sol"
    if args.check:
        if destination.read_text() != generated:
            raise AssertionError("reference corpus differs; regenerate it")
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(generated)
    print(f"4 supplied hashes and {len(vectors)} independent reference cases verified")


if __name__ == "__main__":
    main()
