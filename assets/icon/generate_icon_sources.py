"""Generate the launcher and notification icon sources from the CrowdRadar logo.

Run from the repository root:

    python assets/icon/generate_icon_sources.py
    dart run flutter_launcher_icons

Outputs:
  assets/icon/icon.png             1024x1024 legacy/iOS icon (symbol on white).
  assets/icon/icon_foreground.png  1024x1024 adaptive foreground (transparent,
                                   symbol inside the 66dp safe-zone circle).
  android/app/src/main/res/drawable-*/ic_notification.png
                                   white-on-transparent pin silhouette used as
                                   the FCM notification small icon.

The wordmark ("CROWDRADAR") is dropped: only the pin-and-arcs symbol is used,
because text is illegible at launcher sizes. Requires Pillow.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
LOGO = ROOT / "assets" / "images" / "crowdradar-logo.png"
OUT = ROOT / "assets" / "icon"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

CANVAS = 1024
# Symbol region of the logo (pin + arcs, above the wordmark), in logo pixels.
SYMBOL_BOX = (262, 12, 634, 366)
# Seed pixel inside the dark lower half of the pin, in logo pixels.
PIN_SEED = (450, 330)
# Fraction of the canvas the legacy icon symbol may span (keeps a margin).
LEGACY_FILL = 0.80
# Adaptive icons are masked to a 66dp circle of a 108dp canvas; keep the
# whole symbol inside that circle, with a small extra margin.
ADAPTIVE_SAFE_DIAMETER = CANVAS * 66 / 108 * 0.96
# Notification icon sizes (24dp at each density) and the 20dp live area.
NOTIFICATION_SIZES = {
    "mdpi": 24,
    "hdpi": 36,
    "xhdpi": 48,
    "xxhdpi": 72,
    "xxxhdpi": 96,
}
NOTIFICATION_LIVE_AREA = 20 / 24


def is_dark(pixel):
    r, g, b, a = pixel
    return a > 128 and r + g + b < 300


def symbol(logo):
    return logo.crop(SYMBOL_BOX)


def centered(img, size, scale, background):
    resized = img.resize(
        (round(img.width * scale), round(img.height * scale)), Image.LANCZOS
    )
    canvas = Image.new("RGBA", (size, size), background)
    offset = ((size - resized.width) // 2, (size - resized.height) // 2)
    canvas.alpha_composite(resized, offset)
    return canvas


def legacy_icon(sym):
    scale = CANVAS * LEGACY_FILL / max(sym.size)
    return centered(sym, CANVAS, scale, (255, 255, 255, 255))


def adaptive_foreground(sym):
    # Scale so the farthest opaque pixel from the center stays inside the
    # safe-zone circle.
    cx, cy = sym.width / 2, sym.height / 2
    alpha = sym.getchannel("A").load()
    radius = max(
        ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
        for y in range(sym.height)
        for x in range(sym.width)
        if alpha[x, y] > 16
    )
    scale = (ADAPTIVE_SAFE_DIAMETER / 2) / radius
    return centered(sym, CANVAS, scale, (0, 0, 0, 0))


def pin_mask(logo):
    """Binary mask of the pin: its dark body plus the people figures inside."""
    px = logo.load()
    dark = Image.new("L", logo.size, 0)
    dpx = dark.load()
    for y in range(logo.height):
        for x in range(logo.width):
            if is_dark(px[x, y]):
                dpx[x, y] = 255
    # Isolate the pin body: flood fill its connected dark region.
    body = dark.copy()
    ImageDraw.floodfill(body, PIN_SEED, 128)
    body = body.point(lambda v: 255 if v == 128 else 0)
    # Fill the holes of the body (the inner white circle): everything not
    # reachable from the outside without crossing the body.
    outside = body.copy()
    ImageDraw.floodfill(outside, (0, 0), 128)
    filled = outside.point(lambda v: 0 if v == 128 else 255)
    # Dark pixels inside the filled pin: the body plus the people figures,
    # without the radar arcs that run outside it.
    pin = Image.new("L", logo.size, 0)
    pin.paste(dark, (0, 0), filled)
    return pin.crop(filled.getbbox())


def notification_icon(mask, size):
    live = size * NOTIFICATION_LIVE_AREA
    scale = live / max(mask.size)
    resized = mask.resize(
        (max(1, round(mask.width * scale)), max(1, round(mask.height * scale))),
        Image.LANCZOS,
    )
    icon = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    white = Image.new("RGBA", resized.size, (255, 255, 255, 255))
    white.putalpha(resized)
    icon.alpha_composite(
        white, ((size - resized.width) // 2, (size - resized.height) // 2)
    )
    return icon


def main():
    logo = Image.open(LOGO).convert("RGBA")
    sym = symbol(logo)
    OUT.mkdir(parents=True, exist_ok=True)
    legacy_icon(sym).save(OUT / "icon.png")
    adaptive_foreground(sym).save(OUT / "icon_foreground.png")
    mask = pin_mask(logo)
    for density, size in NOTIFICATION_SIZES.items():
        folder = RES / f"drawable-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        notification_icon(mask, size).save(folder / "ic_notification.png")


if __name__ == "__main__":
    main()
