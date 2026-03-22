#!/usr/bin/env python3
"""
ClickGirl キャラクター画像生成スクリプト
HuggingFace API (Counterfeit-V2.5) で画像生成 → 背景除去 → xcassets に追加
"""

import os
import json
import time
import requests
from io import BytesIO
from PIL import Image
from rembg import remove

# =====================
# 設定
# =====================
HF_TOKEN = os.environ.get("HF_TOKEN", "")
MODEL = "gsdf/Counterfeit-V2.5"
API_URL = f"https://router.huggingface.co/hf-inference/models/{MODEL}"

ASSETS_DIR = "/Users/ishidatakeo/Desktop/swiftgame/clickgirl/ClickGirl/ClickGirl/Assets.xcassets"
OUTPUT_W = 784
OUTPUT_H = 1176

# =====================
# キャラクター定義
# =====================
# レアリティ別スタイル修飾子
RARITY_SUFFIX = {
    "N":   "casual office wear, simple clothes, everyday look",
    "R":   "business formal wear, elegant blouse, stylish outfit",
    "SR":  "luxury fashion, designer dress, shiny fabric, detailed accessories",
    "SSR": "ultra glamorous, sparkling gown, ornate jewelry, dramatic lighting, divine aura",
}

NEGATIVE_PROMPT = (
    "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, "
    "fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, "
    "signature, watermark, username, blurry, ugly, duplicate, nsfw"
)

# キャラクターごとのプロンプト定義
# index: (rarity, 衣装メモ)
CHARACTERS = {
    "karen": {
        "base": "1girl, solo, karen, short brown hair, brown eyes, friendly smile, office worker, sales manager",
        "images": {
            # index: rarity
            0: "N", 1: "N", 2: "N", 3: "N",
            4: "R", 5: "R", 6: "R",
            7: "SR", 8: "SR",
            9: "SSR",
        }
    },
    "misaki": {
        "base": "1girl, solo, misaki, long black hair, glasses, intelligent expression, developer, tech lead",
        "images": {
            0: "N", 1: "N", 2: "N",
            3: "R", 4: "R", 5: "R",
            6: "SR",
            7: "SSR",
        }
    },
    "yuki": {
        "base": "1girl, solo, yuki, silver white hair, cool expression, manager, administrative director",
        "images": {
            0: "N", 1: "N", 2: "N", 3: "N",
            4: "R", 5: "R", 6: "R",
            7: "SR", 8: "SR",
            9: "SSR",
        }
    },
    "rio": {
        "base": "1girl, solo, rio, pink hair, energetic smile, marketing director, cheerful",
        "images": {
            0: "N", 1: "N", 2: "N",
            # 追加分（仕様書では追加予定）
            3: "R", 4: "R", 5: "R",
            6: "SR",
            7: "SSR",
        }
    },
    "akari": {
        "base": "1girl, solo, akari, long blonde hair, mature beauty, secretary, president secretary, elegant",
        "images": {
            0: "N", 1: "N", 2: "N",
            3: "R", 4: "R", 5: "R",
            6: "SR",
            7: "SSR",
        }
    },
}

# =====================
# xcassets ヘルパー
# =====================
def make_imageset(name: str, filename: str):
    """imageset フォルダと Contents.json を作成"""
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


def asset_exists(name: str) -> bool:
    """既に画像が存在するか確認"""
    folder = os.path.join(ASSETS_DIR, f"{name}.imageset")
    if not os.path.exists(folder):
        return False
    for f in os.listdir(folder):
        if f.endswith((".jpg", ".png")) and not f == "Contents.json":
            return True
    return False


# =====================
# 画像生成
# =====================
def generate_image(prompt: str, negative_prompt: str, retries: int = 3) -> Image.Image | None:
    """HuggingFace API で画像生成"""
    headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    payload = {
        "inputs": prompt,
        "parameters": {
            "negative_prompt": negative_prompt,
            "width": OUTPUT_W,
            "height": OUTPUT_H,
            "num_inference_steps": 30,
            "guidance_scale": 7.5,
        }
    }

    for attempt in range(retries):
        try:
            resp = requests.post(API_URL, headers=headers, json=payload, timeout=120)
            if resp.status_code == 200:
                return Image.open(BytesIO(resp.content)).convert("RGB")
            elif resp.status_code == 503:
                wait = 20 + attempt * 10
                print(f"  モデル読み込み中... {wait}秒待機")
                time.sleep(wait)
            else:
                print(f"  APIエラー {resp.status_code}: {resp.text[:200]}")
                return None
        except Exception as e:
            print(f"  リクエスト失敗 (試行{attempt+1}): {e}")
            time.sleep(5)

    return None


def remove_background(img: Image.Image) -> Image.Image:
    """rembg で背景を除去して RGBA PNG を返す"""
    buf = BytesIO()
    img.save(buf, format="PNG")
    result_bytes = remove(buf.getvalue())
    return Image.open(BytesIO(result_bytes)).convert("RGBA")


# =====================
# メイン処理
# =====================
def process_character(char_name: str, char_def: dict, skip_existing: bool = True):
    base_prompt = char_def["base"]

    for idx, rarity in sorted(char_def["images"].items()):
        asset_name = f"{char_name}_{idx}"
        nobg_name  = f"{char_name}_{idx}_nobg"

        if skip_existing and asset_exists(asset_name):
            print(f"  [{asset_name}] スキップ（既存）")
            continue

        rarity_style = RARITY_SUFFIX[rarity]
        prompt = (
            f"masterpiece, best quality, {base_prompt}, "
            f"{rarity_style}, "
            f"white background, full body, standing, looking at viewer, "
            f"anime style, detailed face, beautiful eyes"
        )

        print(f"\n  [{asset_name}] 生成中... (rarity={rarity})")
        print(f"  プロンプト: {prompt[:80]}...")

        img = generate_image(prompt, NEGATIVE_PROMPT)
        if img is None:
            print(f"  [{asset_name}] 生成失敗、スキップ")
            continue

        # --- JPG 保存（背景あり）---
        jpg_folder = make_imageset(asset_name, f"{asset_name}.jpg")
        jpg_path = os.path.join(jpg_folder, f"{asset_name}.jpg")
        img.save(jpg_path, "JPEG", quality=90)
        print(f"  [{asset_name}] JPG 保存: {jpg_path}")

        # --- PNG 保存（背景なし）---
        print(f"  [{nobg_name}] 背景除去中...")
        nobg_img = remove_background(img)
        png_folder = make_imageset(nobg_name, f"{nobg_name}.png")
        png_path = os.path.join(png_folder, f"{nobg_name}.png")
        nobg_img.save(png_path, "PNG")
        print(f"  [{nobg_name}] PNG 保存: {png_path}")

        # API 負荷軽減
        time.sleep(2)


def main():
    if HF_TOKEN == "YOUR_HF_TOKEN_HERE":
        print("エラー: HF_TOKEN を設定してください")
        print("  generate_characters.py の HF_TOKEN = ... の行を編集してください")
        return

    print("=== ClickGirl キャラクター画像生成 ===")
    print(f"モデル: {MODEL}")
    print(f"出力サイズ: {OUTPUT_W}×{OUTPUT_H}")
    print(f"保存先: {ASSETS_DIR}")
    print()

    # 生成するキャラクターを選択（コメントアウトで除外）
    targets = [
        # "karen",    # 完成済み
        # "misaki",   # 完成済み
        # "yuki",     # 完成済み
        "rio",      # 3枚→8枚に追加
        "akari",    # 0枚→8枚を生成
    ]

    for char in targets:
        print(f"\n{'='*40}")
        print(f"キャラクター: {char}")
        print(f"{'='*40}")
        process_character(char, CHARACTERS[char], skip_existing=True)

    print("\n\n=== 完了 ===")
    print("Xcode でプロジェクトを開き直すと新しい画像が反映されます。")


if __name__ == "__main__":
    main()
