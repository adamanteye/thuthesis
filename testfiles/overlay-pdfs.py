#!/usr/bin/env python3

import subprocess
import sys
import tempfile
from itertools import zip_longest
from pathlib import Path

from PIL import Image, ImageChops

upper_pdf, lower_pdf = sys.argv[1:3]
output = sys.argv[3] if len(sys.argv) > 3 else "overlay.pdf"

with tempfile.TemporaryDirectory() as directory:
    directory = Path(directory)
    for name, pdf in (("upper", upper_pdf), ("lower", lower_pdf)):
        subprocess.run(
            ["pdftoppm", "-png", "-gray", "-r", "144", pdf, directory / name],
            check=True,
        )

    key = lambda path: int(path.stem.rsplit("-", 1)[1])
    upper = sorted(directory.glob("upper-*.png"), key=key)
    lower = sorted(directory.glob("lower-*.png"), key=key)
    pages = []

    for number, (upper_page, lower_page) in enumerate(
        zip_longest(upper, lower), 1
    ):
        a = Image.open(upper_page).convert("L") if upper_page else None
        b = Image.open(lower_page).convert("L") if lower_page else None
        if a and b and a.size != b.size:
            raise SystemExit(
                f"page {number} size differs: {a.size} != {b.size}"
            )
        size = (a or b).size
        a = a or Image.new("L", size, 255)
        b = b or Image.new("L", size, 255)
        pages.append(Image.merge("RGB", (a, b, ImageChops.darker(a, b))))

    pages[0].save(
        output, save_all=True, append_images=pages[1:], resolution=144
    )
