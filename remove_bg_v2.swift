#!/usr/bin/env swift

import Foundation
import Vision
import CoreImage
import AppKit

func removeBg(inputPath: String, outputPath: String) throws {
    print("処理中: \(URL(fileURLWithPath: inputPath).lastPathComponent)")
    guard let inputImage = CIImage(contentsOf: URL(fileURLWithPath: inputPath)) else {
        print("  ❌ 読み込み失敗"); return
    }
    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
    try handler.perform([request])
    guard let result = request.results?.first else {
        print("  ⚠️  被写体未検出"); return
    }
    let maskPixelBuffer = try result.generateScaledMaskForImage(
        forInstances: result.allInstances, from: handler)
    let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
    let masked = inputImage.applyingFilter("CIBlendWithMask", parameters: [
        kCIInputMaskImageKey:       maskCIImage,
        kCIInputBackgroundImageKey: CIImage.empty()
    ])
    let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
    let cs = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    try context.writePNGRepresentation(of: masked, to: URL(fileURLWithPath: outputPath),
                                       format: .RGBA8, colorSpace: cs)
    print("  ✅ → \(URL(fileURLWithPath: outputPath).lastPathComponent)")
}

let base   = "/Users/ishidatakeo/Desktop/pinkhairchara"
let outDir = "\(base)/nobg"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let targets: [(String, String)] = [
    // カレン: 夜景ヘッドフォン
    ("\(base)/カレン/Default_A_cute_woman_in_her_early_20s_with_large_brown_eyes_an_3 (3)_moreDetail_x2_2736x1536.jpeg",
     "\(outDir)/char_karen.png"),
    // みさき: BBQ川辺
    ("\(base)/みさき/Default_A_beautiful_woman_in_her_early_20s_with_long_black_hai_2.jpg",
     "\(outDir)/char_misaki.png"),
    // ゆき: 夜の噴水
    ("\(base)/ゆき/Default_A_cute_woman_in_her_early_20s_with_short_light_blue_ha_1.jpg",
     "\(outDir)/char_yuki.png"),
]

print("=== 背景除去（3キャラ）===\n")
for (src, out) in targets {
    try removeBg(inputPath: src, outputPath: out)
}
print("\n完了！出力先: \(outDir)/")
