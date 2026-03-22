#!/usr/bin/env swift

import Foundation
import Vision
import CoreImage
import AppKit

// MARK: - 背景除去処理

func removeBg(inputPath: String, outputPath: String) throws {
    print("処理中: \(URL(fileURLWithPath: inputPath).lastPathComponent)")

    guard let inputImage = CIImage(contentsOf: URL(fileURLWithPath: inputPath)) else {
        print("  ❌ 画像を読み込めません: \(inputPath)")
        return
    }

    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
    try handler.perform([request])

    guard let result = request.results?.first else {
        print("  ⚠️  被写体を検出できませんでした。元画像をコピーします。")
        try FileManager.default.copyItem(atPath: inputPath, toPath: outputPath)
        return
    }

    // マスクをスケール合わせして生成
    let maskPixelBuffer = try result.generateScaledMaskForImage(
        forInstances: result.allInstances,
        from: handler
    )
    let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

    // 元画像にマスクを適用して背景を透明化
    let masked = inputImage.applyingFilter("CIBlendWithMask", parameters: [
        kCIInputMaskImageKey:       maskCIImage,
        kCIInputBackgroundImageKey: CIImage.empty()
    ])

    // PNG（透明付き）として書き出し
    let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
    let outURL  = URL(fileURLWithPath: outputPath)
    let cs = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    try context.writePNGRepresentation(of: masked, to: outURL, format: .RGBA8, colorSpace: cs)

    print("  ✅ 完了 → \(outURL.lastPathComponent)")
}

// MARK: - 対象ファイル一覧

let srcDir  = "/Users/ishidatakeo/Desktop/pinkhairchara"
let outDir  = "/Users/ishidatakeo/Desktop/pinkhairchara/nobg"

let targets: [(src: String, out: String)] = [
    ("Default_A_cute_woman_in_her_early_20s_with_large_brown_eyes_an_0.jpg",          "char_akari.png"),
    ("Default_A_beautiful_woman_in_her_early_twenties_She_has_black_0_moreDetail_x2_2736x1536.jpeg", "char_misaki.png"),
    ("a-stunning-japanese-anime-inspired-illustration-of-MQeY6i4_TyiQ3_IcNKngfw-S6y4FHayTn29oZconbj_8g_moreDetail_x2_2560x1440.jpeg", "char_hana.png"),
    ("Default_A_cute_woman_in_her_early_20s_with_light_blue_color_sh_0_moreDetail_x2_2736x1536.jpeg","char_yuki.png"),
    ("caren_bycile.jpeg",                                                              "char_karen.png"),
    ("karen in the train_moreDetail_x2_2736x1536.jpeg",                               "char_karin.png"),
    ("a-serene-japanese-anime-scene-set-in-a-lush-green--bGOB_SZLQHm0p4BT8mhkaA-SUfyyMpISd248A8SkwxR0w_moreDetail_x2_2560x1440.jpeg", "char_sakura.png"),
]

// 出力フォルダを作成
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

print("=== 背景除去スクリプト (Apple Vision Framework) ===\n")

var successCount = 0
for t in targets {
    let src = "\(srcDir)/\(t.src)"
    let out = "\(outDir)/\(t.out)"
    do {
        try removeBg(inputPath: src, outputPath: out)
        successCount += 1
    } catch {
        print("  ❌ エラー: \(error.localizedDescription)")
    }
}

print("\n完了: \(successCount)/\(targets.count) 枚")
print("出力先: \(outDir)/")
