#!/usr/bin/env python3
"""
ClickGirl 画像インポートスクリプト

使い方:
1. Leonardo.ai Web画面で画像を生成・ダウンロード
2. downloaded_images/ フォルダに以下の命名で保存:
     rio_3.jpg, rio_4.jpg ... akari_0.jpg, akari_1.jpg ...
3. このスクリプトを実行
     python3 import_images.py

スクリプトが自動で:
  - 背景除去 → {name}_nobg.png を生成
  - JPG と PNG を xcassets に登録
"""

import os
import json
from io import BytesIO
from PIL import Image
from rembg import remove

DOWNLOAD_DIR = "/Users/ishidatakeo/Desktop/swiftgame/clickgirl/downloaded_images"
ASSETS_DIR   = "/Users/ishidatakeo/Desktop/swiftgame/clickgirl/ClickGirl/ClickGirl/Assets.xcassets"


def make_imageset(name: str, filename: str):
    folder = os.path.join(ASSETS_DIR, f"{name}.imageset")
    os.makedirs(folder, exist_ok=True)
    contents = {
        "images": [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1}
    }
    with open(os.path.join(folder, "Contents.json"), "w") as f:
        json.dump(contents, f, separators=(",", ":"))
    return folder


def remove_background(img: Image.Image) -> Image.Image:
    buf = BytesIO()
    img.save(buf, format="PNG")
    result = remove(buf.getvalue())
    return Image.open(BytesIO(result)).convert("RGBA")


def main():
    files = sorted([
        f for f in os.listdir(DOWNLOAD_DIR)
        if f.lower().endswith((".jpg", ".jpeg", ".png")) and not f.endswith("_nobg.png")
    ])

    if not files:
        print("downloaded_images/ にファイルがありません。")
        print("命名例: rio_3.jpg, akari_0.jpg")
        return

    print(f"=== {len(files)}枚のファイルを処理します ===\n")

    for filename in files:
        name = os.path.splitext(filename)[0]  # 例: rio_3
        src_path = os.path.join(DOWNLOAD_DIR, filename)

        print(f"[{name}] 処理中...")

        img = Image.open(src_path).convert("RGB")

        # JPG → xcassets
        jpg_folder = make_imageset(name, f"{name}.jpg")
        img.save(os.path.join(jpg_folder, f"{name}.jpg"), "JPEG", quality=90)
        print(f"  JPG 登録完了")

        # 背景除去 → PNG → xcassets
        nobg_name = f"{name}_nobg"
        print(f"  背景除去中...")
        nobg_img = remove_background(img)
        png_folder = make_imageset(nobg_name, f"{nobg_name}.png")
        nobg_img.save(os.path.join(png_folder, f"{nobg_name}.png"), "PNG")
        print(f"  PNG 登録完了\n")

    print("=== 完了 ===")
    print("Xcode でプロジェクトを開き直すと画像が反映されます。")


if __name__ == "__main__":
    main()
