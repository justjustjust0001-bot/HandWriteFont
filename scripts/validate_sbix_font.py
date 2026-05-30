#!/usr/bin/env python3
"""Validate sbix table structure in a FontMaker bitmap TTF."""

from __future__ import annotations

import struct
import sys
from pathlib import Path

try:
    from fontTools.ttLib import TTFont
except ImportError:
    print("fontTools required: pip install fonttools")
    sys.exit(1)


def parse_sbix_header(data: bytes) -> dict:
    if len(data) < 12:
        raise ValueError("sbix table too small")

    version, flags, num_strikes = struct.unpack(">HHI", data[0:8])
    strike_offsets = struct.unpack(f">{num_strikes}I", data[8 : 8 + num_strikes * 4])
    return {
        "version": version,
        "flags": flags,
        "num_strikes": num_strikes,
        "strike_offsets": strike_offsets,
    }


def parse_strike(data: bytes, strike_offset: int, num_glyphs: int) -> dict:
    if strike_offset + 4 > len(data):
        raise ValueError("strike offset out of range")

    ppem, resolution = struct.unpack(">HH", data[strike_offset : strike_offset + 4])
    offset_base = strike_offset + 4
    glyph_offsets = struct.unpack(
        f">{num_glyphs + 1}I",
        data[offset_base : offset_base + (num_glyphs + 1) * 4],
    )

    payloads = []
    for glyph_id in range(num_glyphs):
        start = strike_offset + glyph_offsets[glyph_id]
        end = strike_offset + glyph_offsets[glyph_id + 1]
        if end < start:
            raise ValueError(f"glyph {glyph_id}: negative length")
        if end == start:
            payloads.append(None)
            continue
        payload = data[start:end]
        if len(payload) < 8:
            raise ValueError(f"glyph {glyph_id}: payload too small")
        origin_x, origin_y = struct.unpack(">hh", payload[0:4])
        graphic_type = payload[4:8].decode("ascii", errors="replace")
        payloads.append(
            {
                "origin_x": origin_x,
                "origin_y": origin_y,
                "graphic_type": graphic_type,
                "byte_length": len(payload),
            }
        )

    return {
        "ppem": ppem,
        "resolution": resolution,
        "glyph_offsets": glyph_offsets,
        "payloads": payloads,
    }


def validate(path: Path) -> list[str]:
    issues: list[str] = []
    font = TTFont(path)
    required = ["head", "hhea", "maxp", "OS/2", "hmtx", "cmap", "loca", "glyf", "name", "post", "sbix"]
    for tag in required:
        if tag not in font:
            issues.append(f"missing table: {tag}")

    num_glyphs = font["maxp"].numGlyphs
    sbix_data = font.getTableData("sbix")
    header = parse_sbix_header(sbix_data)

    if header["version"] != 1:
        issues.append(f"sbix version should be 1, got {header['version']}")
    if header["flags"] & 1 == 0:
        issues.append("sbix flags bit 0 must be set")
    if header["num_strikes"] != 1:
        issues.append(f"expected 1 strike, got {header['num_strikes']}")

    strike = parse_strike(sbix_data, header["strike_offsets"][0], num_glyphs)
    if strike["ppem"] != 128:
        issues.append(f"unexpected ppem: {strike['ppem']}")

    non_empty = [p for p in strike["payloads"] if p is not None]
    if not non_empty:
        issues.append("no sbix glyph payloads found")

    for index, payload in enumerate(strike["payloads"]):
        if payload is None:
            continue
        if payload["graphic_type"] != "png ":
            issues.append(f"glyph {index}: graphic type must be 'png ', got {payload['graphic_type']!r}")

    try:
        from fontTools.ttLib import TTLibError

        font.save(path)  # round-trip sanity
    except TTLibError as exc:
        issues.append(f"fontTools round-trip failed: {exc}")

    return issues


def main() -> None:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <font.ttf>")
        sys.exit(2)

    path = Path(sys.argv[1])
    if not path.exists():
        print(f"File not found: {path}")
        sys.exit(1)

    issues = validate(path)
    if issues:
        print("VALIDATION FAILED")
        for issue in issues:
            print(f"  - {issue}")
        sys.exit(1)

    print(f"OK: {path}")


if __name__ == "__main__":
    main()
