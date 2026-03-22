#!/usr/bin/env swift
import Foundation
import Vision
import CoreImage

func removeBg(src: String, dst: String) throws {
    guard let ci = CIImage(contentsOf: URL(fileURLWithPath: src)) else { print("  skip: \(src)"); return }
    let req = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(ciImage: ci)
    try handler.perform([req])
    guard let r = req.results?.first else { print("  no subject: \(src)"); return }
    let mask = try r.generateScaledMaskForImage(forInstances: r.allInstances, from: handler)
    let masked = ci.applyingFilter("CIBlendWithMask", parameters: [
        kCIInputMaskImageKey: CIImage(cvPixelBuffer: mask),
        kCIInputBackgroundImageKey: CIImage.empty()
    ])
    let ctx = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
    try ctx.writePNGRepresentation(of: masked, to: URL(fileURLWithPath: dst),
                                   format: .RGBA8, colorSpace: ci.colorSpace ?? CGColorSpaceCreateDeviceRGB())
}

let base = "/Users/ishidatakeo/Desktop/pinkhairchara"
let out  = "\(base)/nobg"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

let karenFiles = [
    "カレン/Default_8k_ultra_high_res_best_quality_photorealistic_ultra_de_1.jpg",
    "カレン/Default_A_cute_woman_in_her_early_20s_with_large_brown_eyes_an_0.jpg",
    "カレン/Default_A_cute_woman_in_her_early_20s_with_large_brown_eyes_an_2 (3).jpg",
    "カレン/Default_A_cute_woman_in_her_early_20s_with_large_brown_eyes_an_3 (1).jpg",
    "カレン/Default_A_cute_woman_in_her_early_20s_with_large_brown_eyes_an_3 (3)_moreDetail_x2_2736x1536.jpeg",
    "カレン/Default_A_night_market_stall_selling_accessories_illuminated_b_1_moreDetail_x2_2736x1536_1.jpeg",
    "カレン/Default_A_night_market_stall_selling_accessories_illuminated_b_1.jpg",
    "カレン/Default_It_is_raining_There_is_a_cardboard_box_at_the_corner_o_1.jpg",
    "カレン/Default_It_is_raining_There_is_a_cardboard_box_at_the_corner_o_2_moreDetail_x2_2736x1536.jpeg",
    "カレン/karen in the train_moreDetail_x2_2736x1536.jpeg",
]
let misakiFiles = [
    "みさき/Default_A_beautiful_woman_in_her_early_20s_with_black_hair_tha_3.jpg",
    "みさき/Default_A_beautiful_woman_in_her_early_20s_with_long_black_hai_0.jpg",
    "みさき/Default_A_beautiful_woman_in_her_early_20s_with_long_black_hai_0のコピー.jpg",
    "みさき/Default_A_beautiful_woman_in_her_early_20s_with_long_black_hai_1.jpg",
    "みさき/Default_A_beautiful_woman_in_her_early_20s_with_long_black_hai_1のコピー.jpg",
    "みさき/Default_A_beautiful_woman_in_her_early_20s_with_long_black_hai_2.jpg",
    "みさき/Default_A_beautiful_woman_in_her_early_20s_with_long_black_hai_2のコピー.jpg",
    "みさき/Default_A_beautiful_woman_in_her_early_twenties_She_has_long_b_3.jpg",
]
let yukiFiles = [
    "ゆき/Default_A_cute_woman_in_her_early_20s_with_light_blue_color_sh_0_moreDetail_x2_2736x1536.jpeg",
    "ゆき/Default_A_cute_woman_in_her_early_20s_with_light_blue_color_sh_0.jpg",
    "ゆき/Default_A_cute_woman_in_her_early_20s_with_short_light_blue_ha_0.jpg",
    "ゆき/Default_A_cute_woman_in_her_early_20s_with_short_light_blue_ha_0のコピー.jpg",
    "ゆき/Default_A_cute_woman_in_her_early_20s_with_short_light_blue_ha_1.jpg",
    "ゆき/Default_A_cute_woman_in_her_early_20s_with_short_light_blue_ha_3.jpg",
    "ゆき/Default_A_cute_woman_in_her_early_20s_with_short_light_blue_ha_3のコピー.jpg",
    "ゆき/Default_A_cute_woman_in_her_early_20s_with_short_light_blue_ha_3のコピー2.jpg",
    "ゆき/Default_A_cute_woman_in_her_late_20s_age_light_blue_short_hair_2.jpg",
    "ゆき/Default_A_cute_woman_in_her_late_20s_with_short_light_blue_hai_2.jpg",
]

let allFiles: [(prefix: String, files: [String])] = [
    ("karen",  karenFiles),
    ("misaki", misakiFiles),
    ("yuki",   yukiFiles),
]

print("=== 全画像 背景除去 ===\n")
var total = 0
for group in allFiles {
    for (i, rel) in group.files.enumerated() {
        let src = "\(base)/\(rel)"
        let dst = "\(out)/\(group.prefix)_\(i)_nobg.png"
        if FileManager.default.fileExists(atPath: dst) {
            print("  ⏭  \(group.prefix)_\(i)_nobg (既存)")
            total += 1
            continue
        }
        print("処理中: \(group.prefix)_\(i)")
        do {
            try removeBg(src: src, dst: dst)
            print("  ✅ \(group.prefix)_\(i)_nobg.png")
            total += 1
        } catch {
            print("  ❌ \(error)")
        }
    }
}
print("\n完了: \(total)/28 枚")
