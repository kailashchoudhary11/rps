"""Generate the Pic Studios app icon (1024x1024 PNG + adaptive foreground variant).

Run with uv (Pillow is installed in a one-shot venv, no permanent dep added):

    uv run --with pillow python tools/generate_icon.py

Outputs:
    assets/icon/icon.png              # 1024x1024, used by flutter_launcher_icons
    assets/icon/foreground.png        # 1024x1024 adaptive foreground (transparent + P)
    assets/icon/play_store_icon.png   # 512x512, the Play Store listing icon
    assets/icon/feature_graphic.png   # 1024x500, the Play Store feature graphic banner

After regenerating, run `dart run flutter_launcher_icons` to populate the
Android mipmap buckets. play_store_icon.png and feature_graphic.png are
uploaded directly to Play Console (Main store listing → Graphics).
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024

# Material orange-700 (#F57C00) — matches the app's AppBar color exactly.
BG = (245, 124, 0)
FG_RGB = (255, 255, 255)
FG_RGBA = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

# Heavy sans-serif. Arial Black ships with every macOS install. The bowl
# of a real typeface P reads correctly as uppercase, where a primitive
# rectangle-plus-circle reads more like lowercase 'p'.
FONT_PATH = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
# Size tuned so the rendered glyph sits comfortably inside Android's
# adaptive-icon safe zone (center 66% — roughly 684px square).
FONT_SIZE = 880

LETTER = "P"


def generate_feature_graphic() -> Image.Image:
    """Render the 1024x500 Play Store feature graphic.

    Layout: orange background, the white "P" mark on the left, "Pic Studios"
    in large bold type to its right, with a tagline beneath. Important
    content stays clear of the extreme edges since Play Store overlays UI
    chrome on portions of the graphic in some contexts.
    """
    width, height = 1024, 500
    img = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(img)

    # Mark on the left — the same Arial Black "P", scaled to fit the banner.
    mark_size = 320
    mark_font = ImageFont.truetype(FONT_PATH, mark_size)
    mark_bbox = draw.textbbox((0, 0), LETTER, font=mark_font)
    mark_w = mark_bbox[2] - mark_bbox[0]
    mark_h = mark_bbox[3] - mark_bbox[1]
    mark_x = 80 - mark_bbox[0]
    mark_y = (height - mark_h) / 2 - mark_bbox[1]
    draw.text((mark_x, mark_y), LETTER, fill=FG_RGB, font=mark_font)

    # Wordmark — "Pic Studios" in a heavy weight to its right.
    title_font = ImageFont.truetype(FONT_PATH, 84)
    title_text = "Pic Studios"
    title_bbox = draw.textbbox((0, 0), title_text, font=title_font)
    title_h = title_bbox[3] - title_bbox[1]

    # Tagline in a regular weight beneath the title.
    tagline_font = ImageFont.truetype(
        "/System/Library/Fonts/Supplemental/Arial.ttf", 34
    )
    tagline_text = "Your event photos, made simple."
    tagline_bbox = draw.textbbox((0, 0), tagline_text, font=tagline_font)
    tagline_h = tagline_bbox[3] - tagline_bbox[1]

    # Stack title + tagline as a single block, vertically centered.
    gap = 14
    block_h = title_h + gap + tagline_h
    block_top = (height - block_h) / 2

    text_x = mark_x + mark_w + 50
    title_y = block_top - title_bbox[1]
    tagline_y = block_top + title_h + gap - tagline_bbox[1]

    draw.text((text_x, title_y), title_text, fill=FG_RGB, font=title_font)
    draw.text((text_x, tagline_y), tagline_text, fill=FG_RGB, font=tagline_font)

    return img


def render_letter(*, transparent_bg: bool, fg_color: tuple) -> Image.Image:
    """Render LETTER centered on a 1024x1024 canvas."""
    if transparent_bg:
        img = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
    else:
        img = Image.new("RGB", (SIZE, SIZE), BG)

    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_PATH, FONT_SIZE)

    # Use the glyph's actual ink bounding box to center visually — Pillow's
    # default anchor uses font line-height which leaves the glyph slightly
    # off-center because of ascender/descender padding.
    bbox = draw.textbbox((0, 0), LETTER, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (SIZE - text_w) / 2 - bbox[0]
    y = (SIZE - text_h) / 2 - bbox[1]

    draw.text((x, y), LETTER, fill=fg_color, font=font)
    return img


def main() -> None:
    out = Path("assets/icon")
    out.mkdir(parents=True, exist_ok=True)

    # Full launcher icon: solid orange + white P.
    icon = render_letter(transparent_bg=False, fg_color=FG_RGB)
    icon.save(out / "icon.png", "PNG", optimize=True)

    # Adaptive foreground: transparent + white P.
    render_letter(transparent_bg=True, fg_color=FG_RGBA).save(
        out / "foreground.png", "PNG", optimize=True
    )

    # Play Store listing icon (512x512). Downsampled from the 1024 master with
    # Lanczos to keep the letter edges crisp at the smaller size.
    icon.resize((512, 512), Image.LANCZOS).save(
        out / "play_store_icon.png", "PNG", optimize=True
    )

    # Play Store feature graphic (1024x500 banner).
    generate_feature_graphic().save(
        out / "feature_graphic.png", "PNG", optimize=True
    )

    for f in (
        out / "icon.png",
        out / "foreground.png",
        out / "play_store_icon.png",
        out / "feature_graphic.png",
    ):
        print(f"wrote {f} ({f.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
