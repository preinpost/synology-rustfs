#!/usr/bin/env python3
"""Generate the package icon (spk/rustfs/src/rustfs.png, 256x256).

Original artwork (stylised storage bucket with "RS"), not the RustFS logo.
Usage: python3 scripts/make-icon.py [output.png]   (requires Pillow)
"""
import sys
from PIL import Image, ImageDraw, ImageFont

out = sys.argv[1] if len(sys.argv) > 1 else "spk/rustfs/src/rustfs.png"
S = 1024
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle((40, 40, S - 40, S - 40), radius=200, fill=(183, 65, 14, 255))
# bucket
d.polygon([(250, 330), (774, 330), (700, 820), (324, 820)], fill=(255, 255, 255, 255))
d.ellipse((250, 260, 774, 400), fill=(255, 255, 255, 255))
d.ellipse((290, 285, 734, 375), fill=(120, 40, 8, 255))
try:
    font = ImageFont.truetype("DejaVuSans-Bold.ttf", 220)
except OSError:
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 220)
    except OSError:
        font = ImageFont.load_default()
d.text((512, 600), "RS", fill=(183, 65, 14, 255), font=font, anchor="mm")
img.resize((256, 256), Image.LANCZOS).save(out)
print(out)
