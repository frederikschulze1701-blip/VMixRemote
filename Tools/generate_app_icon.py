# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "Sources" / "VMixRemoteApp" / "Resources"
ICONSET = RESOURCES / "AppIcon.iconset"
PNG_PATH = RESOURCES / "AppIcon.png"


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / (size - 1)
        row = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(size):
            pixels[x, y] = row
    return image


def draw_icon(size: int) -> Image.Image:
    scale = size / 1024
    base = vertical_gradient(size, (35, 47, 59), (11, 16, 23)).convert("RGBA")
    mask = rounded_mask(size, int(215 * scale))
    icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon.alpha_composite(base)
    icon.putalpha(mask)

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        (int(90 * scale), int(-150 * scale), int(920 * scale), int(680 * scale)),
        fill=(71, 173, 186, 70),
    )
    glow_draw.ellipse(
        (int(410 * scale), int(250 * scale), int(1150 * scale), int(1050 * scale)),
        fill=(232, 196, 88, 48),
    )
    icon.alpha_composite(glow.filter(ImageFilter.GaussianBlur(int(58 * scale))))

    draw = ImageDraw.Draw(icon)
    inset = int(96 * scale)
    draw.rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=int(150 * scale),
        outline=(255, 255, 255, 42),
        width=max(2, int(5 * scale)),
    )

    # Mixer rails.
    rail_top = int(245 * scale)
    rail_bottom = int(795 * scale)
    rail_width = max(8, int(17 * scale))
    rail_positions = [270, 415, 560, 705]
    rail_colors = [
        (82, 190, 198, 235),
        (122, 218, 166, 235),
        (236, 194, 89, 235),
        (236, 119, 101, 235),
    ]

    for raw_x, color in zip(rail_positions, rail_colors):
        x = int(raw_x * scale)
        shadow_box = (
            x - rail_width,
            rail_top,
            x + rail_width,
            rail_bottom,
        )
        draw.rounded_rectangle(shadow_box, radius=rail_width, fill=(0, 0, 0, 82))
        draw.rounded_rectangle(
            (x - rail_width // 2, rail_top, x + rail_width // 2, rail_bottom),
            radius=rail_width // 2,
            fill=(255, 255, 255, 45),
        )
        active_height = int((rail_bottom - rail_top) * (0.35 + 0.12 * math.sin(raw_x)))
        draw.rounded_rectangle(
            (x - rail_width // 2, rail_bottom - active_height, x + rail_width // 2, rail_bottom),
            radius=rail_width // 2,
            fill=color,
        )

    knob_ys = [620, 480, 565, 390]
    for raw_x, raw_y, color in zip(rail_positions, knob_ys, rail_colors):
        x = int(raw_x * scale)
        y = int(raw_y * scale)
        radius = int(48 * scale)
        draw.rounded_rectangle(
            (x - int(70 * scale), y - radius, x + int(70 * scale), y + radius),
            radius=int(22 * scale),
            fill=(236, 242, 244, 238),
        )
        draw.rounded_rectangle(
            (x - int(70 * scale), y - radius, x + int(70 * scale), y + radius),
            radius=int(22 * scale),
            outline=(255, 255, 255, 160),
            width=max(1, int(3 * scale)),
        )
        draw.line(
            (x - int(36 * scale), y, x + int(36 * scale), y),
            fill=color,
            width=max(3, int(8 * scale)),
        )

    # EQ curve.
    curve_points = []
    for step in range(180):
        x = int((190 + step * 3.6) * scale)
        phase = step / 179
        y = int((238 + math.sin(phase * math.pi * 2.1) * 34 - math.sin(phase * math.pi * 5.2) * 14) * scale)
        curve_points.append((x, y))
    draw.line(curve_points, fill=(245, 248, 250, 215), width=max(4, int(8 * scale)), joint="curve")
    for x, y in curve_points[::45]:
        r = int(17 * scale)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(82, 190, 198, 255))

    # Subtle V mark.
    draw.line(
        (
            int(322 * scale),
            int(856 * scale),
            int(512 * scale),
            int(914 * scale),
            int(702 * scale),
            int(856 * scale),
        ),
        fill=(255, 255, 255, 62),
        width=max(6, int(15 * scale)),
        joint="curve",
    )

    shine = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shine_draw = ImageDraw.Draw(shine)
    shine_draw.rounded_rectangle(
        (int(122 * scale), int(108 * scale), int(902 * scale), int(452 * scale)),
        radius=int(142 * scale),
        fill=(255, 255, 255, 26),
    )
    icon.alpha_composite(shine.filter(ImageFilter.GaussianBlur(int(1 * scale))))

    return icon


def write_iconset() -> None:
    RESOURCES.mkdir(parents=True, exist_ok=True)
    ICONSET.mkdir(parents=True, exist_ok=True)
    base = draw_icon(1024)
    base.save(PNG_PATH)

    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for filename, output_size in sizes:
        resized = base.resize((output_size, output_size), Image.Resampling.LANCZOS)
        resized.save(ICONSET / filename)


if __name__ == "__main__":
    write_iconset()
    print(PNG_PATH)
    print(ICONSET)
