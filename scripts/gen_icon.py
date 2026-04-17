#!/usr/bin/env python3
"""Generate CuePrompt app icon at all required sizes."""

from PIL import Image, ImageDraw
import os

def draw_icon(size):
    """Draw the CuePrompt icon at a given pixel size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = size
    pad = s * 0.08

    # --- Background: deep dark rounded square ---
    corner = s * 0.22
    draw.rounded_rectangle(
        [pad, pad, s - pad, s - pad],
        radius=corner,
        fill=(18, 18, 22, 255)
    )

    # Subtle top highlight (thin, not a full wash)
    highlight_h = s * 0.03
    draw.rounded_rectangle(
        [pad + corner * 0.5, pad, s - pad - corner * 0.5, pad + highlight_h],
        radius=highlight_h / 2,
        fill=(255, 255, 255, 12)
    )

    # --- Dynamic Island pill (top center) ---
    pill_w = s * 0.38
    pill_h = s * 0.065
    pill_x = (s - pill_w) / 2
    pill_y = pad + s * 0.09
    pill_r = pill_h / 2
    draw.rounded_rectangle(
        [pill_x, pill_y, pill_x + pill_w, pill_y + pill_h],
        radius=pill_r,
        fill=(45, 45, 52, 255)
    )
    # Green mic dot
    dot_r = s * 0.015
    dot_cx = pill_x + pill_h * 0.65
    dot_cy = pill_y + pill_h / 2
    draw.ellipse(
        [dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
        fill=(48, 209, 88, 255)
    )
    # Tiny progress bar in pill
    bar_y = pill_y + pill_h - s * 0.008
    bar_h = s * 0.004
    bar_left = pill_x + s * 0.01
    bar_right = pill_x + pill_w * 0.6  # 60% progress
    draw.rounded_rectangle(
        [bar_left, bar_y, bar_right, bar_y + bar_h],
        radius=bar_h / 2,
        fill=(48, 209, 88, 100)
    )

    # --- Script text lines ---
    margin_l = pad + s * 0.14
    margin_r = s - pad - s * 0.14
    line_h = s * 0.024
    line_gap = s * 0.048
    first_line_y = pill_y + pill_h + s * 0.09

    # Line widths as fractions of max width (natural variation)
    line_specs = [
        (0.92, "past"),
        (0.78, "past"),
        (0.88, "past"),
        (0.95, "current"),   # <-- reading position
        (0.82, "upcoming"),
        (0.70, "upcoming"),
        (0.90, "upcoming"),
        (0.65, "upcoming"),
        (0.85, "upcoming"),
    ]

    for i, (w_frac, role) in enumerate(line_specs):
        y = first_line_y + i * line_gap
        if y + line_h > s - pad - s * 0.05:
            break

        line_w = (margin_r - margin_l) * w_frac
        r = line_h / 2

        if role == "past":
            color = (255, 255, 255, 50)
        elif role == "current":
            color = (255, 255, 255, 240)
        else:
            color = (255, 255, 255, 130)

        draw.rounded_rectangle(
            [margin_l, y, margin_l + line_w, y + line_h],
            radius=r, fill=color
        )

    # --- Glow on current line ---
    curr_idx = next(i for i, (_, r) in enumerate(line_specs) if r == "current")
    curr_y = first_line_y + curr_idx * line_gap
    curr_w = (margin_r - margin_l) * line_specs[curr_idx][0]

    for g in range(5, 0, -1):
        ga = int(8 * g)
        off = g * s * 0.005
        draw.rounded_rectangle(
            [margin_l - off, curr_y - off,
             margin_l + curr_w + off, curr_y + line_h + off],
            radius=line_h / 2 + off,
            fill=(80, 140, 255, ga)
        )

    # --- Microphone icon (bottom right) ---
    mic_cx = s * 0.76
    mic_cy = s * 0.80
    mic_w = s * 0.032
    mic_h = s * 0.058
    mic_color = (80, 140, 255, 200)
    mic_color_light = (80, 140, 255, 120)

    # Mic capsule
    draw.rounded_rectangle(
        [mic_cx - mic_w, mic_cy - mic_h,
         mic_cx + mic_w, mic_cy + mic_h * 0.15],
        radius=mic_w,
        fill=mic_color
    )
    # Arc around mic
    arc_r = mic_w * 2.0
    arc_w = max(1, int(s * 0.008))
    draw.arc(
        [mic_cx - arc_r, mic_cy - mic_h * 0.5,
         mic_cx + arc_r, mic_cy + mic_h * 0.6],
        start=210, end=330,
        fill=mic_color_light, width=arc_w
    )
    # Stand line
    stand_w = max(1, int(s * 0.006))
    draw.line(
        [(mic_cx, mic_cy + mic_h * 0.15), (mic_cx, mic_cy + mic_h * 0.5)],
        fill=mic_color_light, width=stand_w
    )
    # Base
    base_w = mic_w * 1.2
    draw.line(
        [(mic_cx - base_w, mic_cy + mic_h * 0.5),
         (mic_cx + base_w, mic_cy + mic_h * 0.5)],
        fill=mic_color_light, width=stand_w
    )

    return img


def main():
    project = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    iconset_dir = os.path.join(project, "AppIcon.iconset")
    os.makedirs(iconset_dir, exist_ok=True)

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

    for name, px in sizes:
        img = draw_icon(px)
        path = os.path.join(iconset_dir, name)
        img.save(path, "PNG")
        print(f"  {name} ({px}x{px})")

    # Convert to .icns
    icns_path = os.path.join(project, "CuePrompt.app", "Contents", "Resources", "AppIcon.icns")
    os.makedirs(os.path.dirname(icns_path), exist_ok=True)

    ret = os.system(f'iconutil -c icns -o "{icns_path}" "{iconset_dir}"')
    if ret == 0:
        print(f"\nIcon installed: {icns_path}")
    else:
        print(f"\niconutil failed (exit {ret}). PNGs are in {iconset_dir}")

    # Save a 1024px preview
    preview = draw_icon(1024)
    preview_path = os.path.join(project, "icon_preview.png")
    preview.save(preview_path, "PNG")
    print(f"Preview: {preview_path}")

    if ret == 0:
        import shutil
        shutil.rmtree(iconset_dir)


if __name__ == "__main__":
    main()
