# Leonardo.ai 画像生成設定

## 基本設定

| 項目 | 設定値 |
|------|--------|
| Model | Leonardo Anime XL |
| Style | anime illustration |
| Contrast | Low（1） |
| Image Dimensions | 2:3 |
| Size | 784 × 1176 |
| Guidance Scale | 7 |
| Inference Steps | 30 |

## Negative Prompt

```
low quality, blurry, bad anatomy, extra fingers, deformed face, watermark, text,
ugly face, asymmetrical face, crooked face, distorted face, disfigured,
bad proportions, malformed, fused features, poorly drawn face, cloned face,
double face, mutation, mutated, gross proportions, missing eyes, extra eyes,
oversaturated, unnatural colors, color bleeding, neon colors, weird colors,
rainbow hair, multicolored hair, color noise, chromatic aberration
```

## Prompt テンプレート

```
anime, Makoto Shinkai style, cinematic, masterpiece, best quality,
1girl, solo, {キャラ特徴}, {レアリティ別衣装・背景},
depth of field, bokeh background, beautiful detailed background,
atmospheric lighting, highly detailed, looking at viewer
```

## キャラクター別 特徴

| キャラ | prefix | 髪色・特徴 |
|--------|--------|-----------|
| カレン | karen | short pink hair, friendly smile, sales manager |
| みさき | misaki | long black hair, glasses, intelligent expression, developer |
| ゆき | yuki | silver white hair, cool expression, administrative director |
| りお | rio | short pink hair, energetic smile, marketing director |
| あかり | akari | long blonde hair, mature beauty, president secretary |

## レアリティ別 衣装・背景

| レアリティ | 衣装 | 背景 |
|-----------|------|------|
| N | casual everyday outfit | outdoor, park or city street, natural sunlight |
| R | business formal wear, elegant blouse | indoor office, warm sunlight through window |
| SR | luxury fashion, designer dress | beautiful restaurant or rooftop, golden hour lighting |
| SSR | ultra glamorous gown, ornate jewelry | night cityscape, bokeh lights, dramatic cinematic lighting |

## 画像追加手順

1. 上記設定で Leonardo.ai Web画面（[leonardo.ai](https://leonardo.ai)）で生成
2. ダウンロードして命名規則に従いリネーム
   ```
   {prefix}_{index}.jpg  例: rio_3.jpg / akari_0.jpg
   ```
3. 以下のフォルダに配置:
   ```
   swiftgame/clickgirl/downloaded_images/
   ```
4. Claude Code に「インポートして」と依頼
   → `import_images.py` が背景除去・xcassets登録を自動実行

## 備考

- Web画面は無料150トークン/日（毎日リセット）
- APIは有料のため使用しない
- 既存の karen / yuki のスタイルに合わせること
- 生成後の背景除去・xcassets登録は `import_images.py` で自動化
