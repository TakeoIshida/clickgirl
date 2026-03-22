# Leonardo.ai 画像生成設定

## 基本設定

| 項目 | 設定値 |
|------|--------|
| Model | Anime Style |
| Style | anime illustration |
| Contrast | Medium |
| Image Dimensions | 2:3 |
| Medium | 784 × 1176 |

## Negative Prompt

```
low quality, blurry, bad anatomy, extra fingers, deformed face, watermark, text
```

## キャラクター別プロンプト（参考）

### rio（ピンク髪・マーケティング部長）
- N: casual outfit, energetic smile, outdoor background
- R: business suit, office background
- SR: luxury dress, rooftop background, golden hour
- SSR: glamorous gown, night cityscape, sparkling lights

### akari（金髪・社長秘書）
- N: casual elegant outfit, indoor background
- R: formal blouse, office background, warm light
- SR: designer dress, upscale restaurant background
- SSR: ornate gown, jewelry, night city background

## 備考

- 既存の karen / yuki / misaki 画像のスタイルに合わせること
- 生成後は rembg で背景除去して `_nobg.png` を作成する
- xcassets への登録は `generate_characters.py` で自動化済み
