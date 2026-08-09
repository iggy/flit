#!/usr/bin/env python3
"""Regenerate every platform app-icon asset from the master artwork.

The master artwork (repo root `icon.png`) is a rounded-square badge drawn on a
near-white canvas. Platforms need three different shapes of the same art:

* **full bleed** — the badge's navy->blue gradient extrapolated into the four
  corners so the image is a true opaque square. iOS, Android adaptive
  backgrounds, Windows, Linux and the web icons all want this: those platforms
  either apply their own corner mask or conventionally show a square tile, and
  a rounded-inside-rounded icon would leave white nubs at the corners.
* **rounded** — the badge exactly as drawn, with transparent corners. macOS
  does *not* mask app icons, so the artwork has to carry its own rounding
  (inset on the canvas per Apple's icon grid). Android legacy launcher bitmaps
  are also pre-shaped.
* **inset** — the whole badge scaled down inside a larger canvas so it survives
  an aggressive mask (Android adaptive foreground, web maskable icons).

Usage (from `app/`):

    python3 packaging/generate_app_icons.py            # rewrite all assets
    python3 packaging/generate_app_icons.py --preview  # also write /tmp sheet

Requires Pillow and numpy (host tooling only — not a Flutter dependency).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image, ImageFilter
except ImportError as exc:  # pragma: no cover - developer tooling
    sys.exit(f"error: this script needs Pillow and numpy ({exc})")

# --- Master artwork geometry -------------------------------------------------
#
# Measured from the source PNG rather than guessed: the badge is the only
# non-background region, its corners fit a circle of radius 115 on a 587px
# side, and CONTENT_BOX bounds the flourish + "FLIT" wordmark inside it.
BADGE_ORIGIN = (411, 90)
BADGE_SIDE = 587
BADGE_RADIUS = 115.0
CONTENT_BOX = (156, 89, 470, 494)  # x0, y0, x1, y1 within the badge

# The artwork's own antialiased edge blends to white over roughly 2.5px inside
# the nominal boundary. Treat everything shallower than this as "not artwork"
# so the corner fill replaces the white fringe instead of preserving it as a
# bright arc.
EDGE_FEATHER = 3.0

MASTER_SIDE = 1024

# Fraction of the canvas the badge occupies in the "inset" renders.
#
# Android adaptive icons guarantee only the central 66 of 108dp; scaling the
# badge to that fraction keeps the wordmark clear of every launcher mask.
ANDROID_SAFE_FRACTION = 66 / 108
# A web maskable icon must survive a circle of 80% diameter. A rounded square
# of side s has its farthest point at s * (0.304*sqrt(2) + 0.196) = 0.626*s
# from centre, so s <= 0.4/0.626 = 0.639 of the canvas fits entirely inside.
WEB_MASKABLE_FRACTION = 0.63
# Apple's macOS icon grid: an 824px body centred on a 1024px canvas.
MACOS_BODY_FRACTION = 824 / 1024


def _fit_gradient(badge: np.ndarray, inside: np.ndarray) -> np.ndarray:
    """Fit a quadratic surface per channel to the badge's gradient backdrop.

    Only bluish, non-highlight pixels are sampled so the white flourish and
    wordmark don't drag the fit. A quadratic tracks the artwork's gradient to
    ~6/255 RMS in the corner band, which is what makes the corner fill seamless
    (a plane is visibly off by ~19).
    """
    height, width, _ = badge.shape
    yy, xx = np.mgrid[0:height, 0:width]
    u = (xx - width / 2) / width
    v = (yy - height / 2) / height

    backdrop = (
        inside
        & (badge[:, :, 2] > badge[:, :, 0] + 25)
        & (badge.max(axis=2) < 210)
    )
    terms = [np.ones_like(u), u, v, u * u, u * v, v * v]
    design = np.stack([t[backdrop] for t in terms], axis=1)
    full = np.stack([t.ravel() for t in terms], axis=1)

    model = np.empty_like(badge)
    for channel in range(3):
        coef, *_ = np.linalg.lstsq(
            design, badge[:, :, channel][backdrop], rcond=None
        )
        model[:, :, channel] = (full @ coef).reshape(height, width)
    return model


def _signed_distance(side: int, radius: float) -> np.ndarray:
    """Signed distance to the rounded-square boundary; negative == inside."""
    yy, xx = np.mgrid[0:side, 0:side]
    cx = np.clip(xx, radius, side - 1 - radius)
    cy = np.clip(yy, radius, side - 1 - radius)
    return np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) - radius


def _smooth_backdrop(
    badge: np.ndarray, inside: np.ndarray, model: np.ndarray
) -> np.ndarray:
    """Model plus the artwork's low-frequency residual, defined everywhere.

    The quadratic alone is a touch flatter than the real gradient, but the raw
    residual carries the artwork's compression noise -- extrapolating it
    outward by nearest-neighbour turns that noise into radial spokes. Blurring
    the residual first (normalised by a blurred validity mask so the content and
    the white surround don't bleed in) keeps the useful low-frequency correction
    and throws away the noise, leaving a backdrop that is smooth everywhere and
    still matches the artwork at the boundary to within a couple of levels.
    """
    backdrop = (
        inside
        & (badge[:, :, 2] > badge[:, :, 0] + 25)
        & (badge.max(axis=2) < 210)
    )
    weight = Image.fromarray((backdrop * 255).astype(np.uint8), "L")
    blur = ImageFilter.GaussianBlur(radius=24)
    weight_blur = np.asarray(weight.filter(blur)).astype(float) / 255.0

    # Where few sampled pixels landed in the blur kernel -- the corner wedges,
    # which have no artwork at all -- the normalised residual is the ratio of
    # two near-zero numbers and blows up. Fade the correction out as confidence
    # drops so those regions fall back to the bare quadratic.
    confidence = np.clip(weight_blur / 0.25, 0.0, 1.0)
    denominator = np.maximum(weight_blur, 0.05)

    smooth = model.copy()
    for channel in range(3):
        residual = np.where(backdrop, badge[:, :, channel] - model[:, :, channel], 0.0)
        # Offset by +128 so the uint8 round-trip can carry negative residuals.
        packed = Image.fromarray(
            np.clip(residual + 128.0, 0, 255).astype(np.uint8), "L"
        )
        blurred = np.asarray(packed.filter(blur)).astype(float) - 128.0
        smooth[:, :, channel] = (
            model[:, :, channel] + blurred / denominator * confidence
        )

    # Keep the extrapolation inside the gamut the artwork actually uses. Beyond
    # the badge the quadratic keeps climbing, and clipping per channel would
    # push blue past its ceiling while green kept rising -- that reads as teal
    # in the corners. Scaling each pixel's colour toward the observed maximum
    # instead preserves hue.
    ceiling = np.percentile(badge[backdrop], 99.9, axis=0)
    floor = np.percentile(badge[backdrop], 0.1, axis=0)
    over = np.maximum(smooth / np.maximum(ceiling, 1e-6), 1.0).max(axis=2)
    smooth = smooth / over[:, :, None]
    return np.clip(smooth, floor, ceiling)


def _build_masters(
    source: Path,
) -> tuple[Image.Image, Image.Image, Image.Image, tuple[int, int, int]]:
    """Return (full-bleed, rounded, content-free backdrop, adaptive navy)."""
    art = np.asarray(Image.open(source).convert("RGB")).astype(float)
    x0, y0 = BADGE_ORIGIN
    badge = art[y0 : y0 + BADGE_SIDE, x0 : x0 + BADGE_SIDE].copy()

    sd = _signed_distance(BADGE_SIDE, BADGE_RADIUS)
    inside = sd < -2
    model = _fit_gradient(badge, inside)
    smooth = _smooth_backdrop(badge, inside, model)

    # Full bleed: keep the real artwork well inside the rounded boundary and
    # hand the corners to the smooth backdrop. The crossover finishes
    # EDGE_FEATHER px *inside* the nominal edge so the artwork's white
    # antialiasing is overwritten rather than left as a bright arc; the gradient
    # is continuous there, so the swap is invisible.
    ramp = np.clip((-sd - EDGE_FEATHER) / 2.0, 0.0, 1.0)[:, :, None]
    filled = np.clip(badge * ramp + smooth * (1.0 - ramp), 0, 255)

    # Alpha for the rounded master still follows the true geometric edge.
    alpha = np.clip(0.5 - sd, 0.0, 1.0)

    def _master(array: np.ndarray, mode: str) -> Image.Image:
        return Image.fromarray(array.astype(np.uint8), mode).resize(
            (MASTER_SIDE, MASTER_SIDE), Image.LANCZOS
        )

    full_bleed = _master(filled, "RGB")
    backdrop = _master(np.clip(smooth, 0, 255), "RGB")
    # Rounded master: same pixels, antialiased rounded-rect alpha.
    rounded = _master(np.dstack([filled, alpha * 255.0]), "RGBA")

    # Representative navy for the adaptive background layer: the mean of the
    # gradient across the badge, which sits between its dark and light ends.
    navy = tuple(int(round(v)) for v in smooth[inside].mean(axis=0))
    return full_bleed, rounded, backdrop, navy  # type: ignore[return-value]


def _resize(master: Image.Image, size: int) -> Image.Image:
    return master.resize((size, size), Image.LANCZOS)


def _flatten(image: Image.Image, background: tuple[int, int, int]) -> Image.Image:
    """Composite onto an opaque background (iOS forbids alpha in app icons)."""
    if image.mode != "RGBA":
        return image.convert("RGB")
    canvas = Image.new("RGB", image.size, background)
    canvas.paste(image, (0, 0), image)
    return canvas


def _inset(
    badge: Image.Image,
    size: int,
    fraction: float,
    background: Image.Image | tuple[int, int, int],
) -> Image.Image:
    """Centre `badge` at `fraction` of a `size` canvas over `background`."""
    if isinstance(background, tuple):
        canvas = Image.new("RGBA", (size, size), background + (255,))
    else:
        canvas = _resize(background, size).convert("RGBA")
    body = max(1, int(round(size * fraction)))
    scaled = badge.resize((body, body), Image.LANCZOS)
    offset = (size - body) // 2
    canvas.paste(scaled, (offset, offset), scaled)
    return canvas


def _write(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    print(f"  {path}")


IOS_ICONS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

MACOS_ICONS = {f"app_icon_{s}.png": s for s in (16, 32, 64, 128, 256, 512, 1024)}

ANDROID_DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

WINDOWS_ICO_SIZES = (16, 24, 32, 48, 64, 128, 256)
LINUX_SIZES = (16, 32, 48, 64, 128, 256, 512)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        type=Path,
        default=Path(__file__).resolve().parents[2] / "icon.png",
        help="master artwork (default: repo-root icon.png)",
    )
    parser.add_argument(
        "--preview",
        action="store_true",
        help="also write a contact sheet to /tmp/flit_icon_preview.png",
    )
    args = parser.parse_args()

    app = Path(__file__).resolve().parents[1]
    if not args.source.is_file():
        return print(f"error: no master artwork at {args.source}") or 1

    print(f"==> Reading master artwork: {args.source}")
    full_bleed, rounded, backdrop, navy = _build_masters(args.source)
    print(f"    adaptive background colour: #{navy[0]:02X}{navy[1]:02X}{navy[2]:02X}")

    print("==> iOS (full bleed, opaque)")
    ios = app / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for name, size in IOS_ICONS.items():
        _write(_flatten(_resize(full_bleed, size), navy), ios / name)

    print("==> macOS (rounded, Apple icon grid)")
    macos = app / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for name, size in MACOS_ICONS.items():
        body = max(1, int(round(size * MACOS_BODY_FRACTION)))
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        scaled = rounded.resize((body, body), Image.LANCZOS)
        offset = (size - body) // 2
        canvas.paste(scaled, (offset, offset), scaled)
        _write(canvas, macos / name)

    print("==> Android (legacy bitmaps + adaptive foreground)")
    res = app / "android/app/src/main/res"
    for density, (legacy, adaptive) in ANDROID_DENSITIES.items():
        _write(_resize(rounded, legacy), res / f"mipmap-{density}/ic_launcher.png")
        foreground = Image.new("RGBA", (adaptive, adaptive), (0, 0, 0, 0))
        body = max(1, int(round(adaptive * ANDROID_SAFE_FRACTION)))
        scaled = rounded.resize((body, body), Image.LANCZOS)
        offset = (adaptive - body) // 2
        foreground.paste(scaled, (offset, offset), scaled)
        _write(foreground, res / f"mipmap-{density}/ic_launcher_foreground.png")

    print("==> Web (favicon, PWA, maskable)")
    web = app / "web"
    _write(_flatten(_resize(full_bleed, 32), navy), web / "favicon.png")
    for size in (192, 512):
        _write(_flatten(_resize(full_bleed, size), navy), web / f"icons/Icon-{size}.png")
        # Maskable icons sit on the plain gradient, never on `full_bleed` --
        # that would show a second copy of the flourish and wordmark behind the
        # inset badge.
        maskable = _inset(rounded, size, WEB_MASKABLE_FRACTION, backdrop)
        _write(_flatten(maskable, navy), web / f"icons/Icon-maskable-{size}.png")

    print("==> Windows (multi-size .ico)")
    ico = app / "windows/runner/resources/app_icon.ico"
    ico.parent.mkdir(parents=True, exist_ok=True)
    _resize(full_bleed, 256).save(
        ico, format="ICO", sizes=[(s, s) for s in WINDOWS_ICO_SIZES]
    )
    print(f"  {ico}")

    print("==> Linux (hicolor sizes for the AppImage/desktop entry)")
    for size in LINUX_SIZES:
        _write(
            _flatten(_resize(full_bleed, size), navy),
            app / f"linux/runner/resources/flit_{size}.png",
        )

    if args.preview:
        sheet = Image.new("RGB", (1024, 256), (245, 246, 248))
        sheet.paste(_resize(full_bleed, 256), (0, 0))
        sheet.paste(_resize(rounded, 256), (256, 0), _resize(rounded, 256))
        sheet.paste(
            _inset(rounded, 256, ANDROID_SAFE_FRACTION, navy), (512, 0)
        )
        sheet.paste(_inset(rounded, 256, WEB_MASKABLE_FRACTION, backdrop), (768, 0))
        preview = Path("/tmp/flit_icon_preview.png")
        sheet.save(preview)
        print(f"==> Preview: {preview}")

    print("\nDone. Adaptive background colour lives in "
          "android/app/src/main/res/values/ic_launcher_background.xml —"
          "\nkeep it in sync if the artwork's gradient changes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
