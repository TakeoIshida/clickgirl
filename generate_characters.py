#!/usr/bin/env python3
"""
ClickGirl キャラクター画像生成スクリプト
Leonardo.ai API で画像生成 → 背景除去 → xcassets に追加
"""

import os
import json
import time
import requests
from io import BytesIO
from PIL import Image
from rembg import remove
from dotenv import load_dotenv

# =====================
# 設定
# =====================
load_dotenv("/Users/ishidatakeo/Desktop/swiftgame/clickgirl/ClickGirl/ClickGirl/.env")
TOKEN = os.environ.get("LEONARDO_TOKEN", "")

BASE_URL = "https://cloud.leonardo.ai/api/rest/v1"
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
}

ASSETS_DIR = "/Users/ishidatakeo/Desktop/swiftgame/clickgirl/ClickGirl/ClickGirl/Assets.xcassets"
OUTPUT_W = 784
OUTPUT_H = 1176

# Leonardo Anime XL（アニメ特化モデル）
MODEL_ID = "e71a1c2f-4f80-4800-934f-2c68979d8cc8"  # Leonardo Anime XL

# =====================
# レアリティ別スタイル
# =====================
RARITY_SUFFIX = {
    "N":   "casual everyday outfit, natural lighting, outdoor background, park or city street, warm sunlight",
    "R":   "business formal wear, elegant blouse, indoor office background, warm sunlight through window",
    "SR":  "luxury fashion, designer dress, beautiful restaurant or rooftop background, golden hour lighting",
    "SSR": "ultra glamorous gown, ornate jewelry, night cityscape background, bokeh lights, dramatic cinematic lighting",
}

NEGATIVE_PROMPT = (
    "low quality, blurry, bad anatomy, extra fingers, deformed face, watermark, text, "
    "ugly face, asymmetrical face, crooked face, distorted face, disfigured, "
    "bad proportions, malformed, fused features, poorly drawn face, cloned face, "
    "double face, mutation, mutated, gross proportions, missing eyes, extra eyes, "
    "oversaturated, unnatural colors, color bleeding, neon colors, weird colors, "
    "rainbow hair, multicolored hair, color noise, chromatic aberration"
)

# =====================
# キャラクター定義
# =====================
CHARACTERS = {
    "rio": {
        "base": "1girl, solo, short pink hair, energetic smile, marketing director, cheerful, beautiful eyes",
        "images": {
            0: "N", 1: "N", 2: "N",
            3: "R", 4: "R", 5: "R",
            6: "SR",
            7: "SSR",
        }
    },
    "akari": {
        "base": "1girl, solo, long blonde hair, mature beauty, secretary, president secretary, elegant, beautiful eyes",
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
    folder = os.path.join(ASSETS_DIR, f"{name}.imageset")
    if not os.path.exists(folder):
        return False
    for f in os.listdir(folder):
        if f.endswith((".jpg", ".png", ".jpeg")):
            return True
    return False


# =====================
# Leonardo.ai API
# =====================
def generate_image(prompt: str, negative_prompt: str, retries: int = 3) -> Image.Image | None:
    """Leonardo.ai で画像を生成して PIL Image を返す"""

    # Step 1: 生成ジョブを送信
    payload = {
        "prompt": prompt,
        "negative_prompt": negative_prompt,
        "modelId": MODEL_ID,
        "width": OUTPUT_W,
        "height": OUTPUT_H,
        "num_images": 1,
        "guidance_scale": 7,
        "num_inference_steps": 30,
        "presetStyle": "ILLUSTRATION",
        "contrast": 3.0,
        "public": False,
    }

    for attempt in range(retries):
        try:
            resp = requests.post(f"{BASE_URL}/generations", headers=HEADERS, json=payload, timeout=30)
            if resp.status_code != 200:
                print(f"  生成リクエスト失敗 {resp.status_code}: {resp.text[:200]}")
                return None

            generation_id = resp.json()["sdGenerationJob"]["generationId"]
            break
        except Exception as e:
            print(f"  リクエスト失敗 (試行{attempt+1}): {e}")
            time.sleep(5)
    else:
        return None

    # Step 2: 完了をポーリング
    print(f"  生成中 (ID: {generation_id[:8]}...)  ", end="", flush=True)
    for _ in range(60):
        time.sleep(3)
        try:
            r = requests.get(f"{BASE_URL}/generations/{generation_id}", headers=HEADERS, timeout=15)
            data = r.json().get("generations_by_pk", {})
            status = data.get("status", "")
            if status == "COMPLETE":
                images = data.get("generated_images", [])
                if images:
                    print("完了")
                    img_url = images[0]["url"]
                    img_resp = requests.get(img_url, timeout=30)
                    return Image.open(BytesIO(img_resp.content)).convert("RGB")
                break
            elif status == "FAILED":
                print("失敗")
                return None
            print(".", end="", flush=True)
        except Exception as e:
            print(f"  ポーリングエラー: {e}")

    print("タイムアウト")
    return None


def remove_background(img: Image.Image) -> Image.Image:
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
            f"anime, Makoto Shinkai style, cinematic, masterpiece, best quality, "
            f"{base_prompt}, {rarity_style}, "
            f"depth of field, bokeh background, beautiful detailed background, "
            f"atmospheric lighting, highly detailed, looking at viewer"
        )

        print(f"\n  [{asset_name}] 生成開始 (rarity={rarity})")

        img = generate_image(prompt, NEGATIVE_PROMPT)
        if img is None:
            print(f"  [{asset_name}] 生成失敗、スキップ")
            continue

        # JPG 保存（背景あり）
        jpg_folder = make_imageset(asset_name, f"{asset_name}.jpg")
        jpg_path = os.path.join(jpg_folder, f"{asset_name}.jpg")
        img.save(jpg_path, "JPEG", quality=90)
        print(f"  [{asset_name}] JPG 保存")

        # PNG 保存（背景なし）
        print(f"  [{nobg_name}] 背景除去中...")
        nobg_img = remove_background(img)
        png_folder = make_imageset(nobg_name, f"{nobg_name}.png")
        png_path = os.path.join(png_folder, f"{nobg_name}.png")
        nobg_img.save(png_path, "PNG")
        print(f"  [{nobg_name}] PNG 保存")

        time.sleep(2)


def main():
    if not TOKEN:
        print("エラー: LEONARDO_TOKEN が .env に設定されていません")
        return

    print("=== ClickGirl キャラクター画像生成 (Leonardo.ai) ===")
    print(f"モデル: {MODEL_ID}")
    print(f"出力サイズ: {OUTPUT_W}×{OUTPUT_H}")
    print()

    targets = ["rio", "akari"]

    for char in targets:
        print(f"\n{'='*40}")
        print(f"キャラクター: {char}")
        print(f"{'='*40}")
        process_character(char, CHARACTERS[char], skip_existing=True)

    print("\n\n=== 完了 ===")
    print("Xcode でプロジェクトを開き直すと新しい画像が反映されます。")


if __name__ == "__main__":
    main()
