from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
FIG = ROOT / "outputs" / "figures"
OUT = FIG / "contact_sheet.png"


def main():
    files = sorted(p for p in FIG.glob("*.png") if p.name != OUT.name)
    thumbs = []
    for path in files:
        image = Image.open(path).convert("RGB")
        image.thumbnail((420, 280))
        canvas = Image.new("RGB", (450, 330), "white")
        canvas.paste(image, ((450 - image.width) // 2, 12))
        draw = ImageDraw.Draw(canvas)
        draw.text((12, 302), path.name, fill=(0, 0, 0))
        thumbs.append(canvas)

    cols = 2
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * 450, rows * 330), (245, 245, 245))
    for i, thumb in enumerate(thumbs):
        sheet.paste(thumb, ((i % cols) * 450, (i // cols) * 330))
    sheet.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()

