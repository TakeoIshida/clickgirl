#!/bin/bash

# 使い方: bash setup_assets.sh <Xcodeプロジェクトのフォルダパス>
# 例: bash setup_assets.sh /Users/ishidatakeo/Desktop/swiftgame/clickgirl/ClickGirl

SRC="/Users/ishidatakeo/Desktop/pinkhairchara"
NOBG="$SRC/nobg"
DEST="${1}/ClickGirl/Assets.xcassets"

if [ -z "$1" ]; then
  echo "使い方: bash setup_assets.sh <プロジェクトフォルダ>"
  exit 1
fi

if [ ! -d "$DEST" ]; then
  echo "Assets.xcassetsが見つかりません: $DEST"
  exit 1
fi

# 背景ありコピー（元ファイルから）
copy_image() {
  local src="$1"
  local name="$2"
  local folder="$DEST/$name.imageset"
  mkdir -p "$folder"
  local ext="${src##*.}"
  cp "$SRC/$src" "$folder/$name.$ext"
  cat > "$folder/Contents.json" <<EOF
{
  "images": [
    { "filename": "$name.$ext", "idiom": "universal", "scale": "1x" },
    { "idiom": "universal", "scale": "2x" },
    { "idiom": "universal", "scale": "3x" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
EOF
  echo "  ✅ $name"
}

# 背景なしコピー（nobgフォルダのPNGから）
copy_nobg() {
  local filename="$1"   # 例: char_akari.png
  local name="${filename%.png}_nobg"   # → char_akari_nobg
  local folder="$DEST/$name.imageset"
  mkdir -p "$folder"
  cp "$NOBG/$filename" "$folder/$name.png"
  cat > "$folder/Contents.json" <<EOF
{
  "images": [
    { "filename": "$name.png", "idiom": "universal", "scale": "1x" },
    { "idiom": "universal", "scale": "2x" },
    { "idiom": "universal", "scale": "3x" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
EOF
  echo "  ✅ $name"
}

echo "=== 背景あり画像 ==="
copy_image "Default_A_cute_woman_in_her_early_20s_with_large_brown_eyes_an_0.jpg"                                                                              "char_akari"
copy_image "Default_A_beautiful_woman_in_her_early_twenties_She_has_black_0_moreDetail_x2_2736x1536.jpeg"                                                      "char_misaki"
copy_image "a-stunning-japanese-anime-inspired-illustration-of-MQeY6i4_TyiQ3_IcNKngfw-S6y4FHayTn29oZconbj_8g_moreDetail_x2_2560x1440.jpeg"                    "char_hana"
copy_image "Default_A_cute_woman_in_her_early_20s_with_light_blue_color_sh_0_moreDetail_x2_2736x1536.jpeg"                                                     "char_yuki"
copy_image "caren_bycile.jpeg"                                                                                                                                  "char_karen"
copy_image "karen in the train_moreDetail_x2_2736x1536.jpeg"                                                                                                   "char_karin"
copy_image "a-serene-japanese-anime-scene-set-in-a-lush-green--bGOB_SZLQHm0p4BT8mhkaA-SUfyyMpISd248A8SkwxR0w_moreDetail_x2_2560x1440.jpeg"                    "char_sakura"
copy_image "Default_A_night_scene_with_a_sparkling_starry_sky_The_neon_lig_0_moreDetail_x2_2736x1536_2.jpeg"                                                   "bg_city"

echo ""
echo "=== 背景なし画像（切り抜き）==="
copy_nobg "char_akari.png"
copy_nobg "char_misaki.png"
copy_nobg "char_hana.png"
copy_nobg "char_yuki.png"
copy_nobg "char_karen.png"
copy_nobg "char_karin.png"
copy_nobg "char_sakura.png"

echo ""
echo "=== BGM ==="
cp "$SRC/雨の曲.mp3" "$1/ClickGirl/雨の曲.mp3"
echo "  ✅ 雨の曲.mp3"

echo ""
echo "完了！"
echo "  背景あり : char_akari / char_misaki / char_hana / char_yuki / char_karen / char_karin / char_sakura"
echo "  背景なし : char_akari_nobg / char_misaki_nobg / ... (同名_nobg)"
echo "  背景     : bg_city"
