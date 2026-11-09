import AppKit

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let isIPad = CommandLine.arguments.contains("--ipad")
let outputRoot = projectRoot.appendingPathComponent(isIPad ? "StoreAssets/v1.1/iPad-13" : "StoreAssets/v1.1/iPhone-6.5")
let inputRoot = isIPad ? "StoreAssets/iPad-13" : "StoreAssets/iPhone-6.5"
try FileManager.default.createDirectory(at: outputRoot, withIntermediateDirectories: true)

let canvasSize = isIPad ? NSSize(width: 2048, height: 2732) : NSSize(width: 1242, height: 2688)
let darkGreen = NSColor(calibratedRed: 0.11, green: 0.24, blue: 0.18, alpha: 1)
let gold = NSColor(calibratedRed: 0.76, green: 0.49, blue: 0.18, alpha: 1)
let cream = NSColor(calibratedRed: 0.97, green: 0.94, blue: 0.87, alpha: 1)

func text(_ value: String, size: CGFloat, color: NSColor, y: CGFloat, weight: NSFont.Weight = .bold) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    (value as NSString).draw(in: NSRect(x: 55, y: y, width: canvasSize.width - 110, height: size * 1.45), withAttributes: attributes)
}

func writeCanvas(name: String, draw: () -> Void) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { throw NSError(domain: "StoreAssets", code: 1) }
    let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    NSGraphicsContext.current?.imageInterpolation = .high
    NSGradient(colors: [cream, NSColor.white])!.draw(in: NSRect(origin: .zero, size: canvasSize), angle: 90)
    draw()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "StoreAssets", code: 1)
    }
    try data.write(to: outputRoot.appendingPathComponent(name))
}

func drawScreen(_ path: String) {
    guard let image = NSImage(contentsOfFile: projectRoot.appendingPathComponent(path).path) else { return }
    let horizontalMargin = canvasSize.width * 0.0813
    let availableWidth = canvasSize.width - horizontalMargin * 2
    let availableHeight = canvasSize.height - 438
    let imageRatio = image.size.width / image.size.height
    var frameWidth = availableWidth
    var frameHeight = frameWidth / imageRatio
    if frameHeight > availableHeight {
        frameHeight = availableHeight
        frameWidth = frameHeight * imageRatio
    }
    let frame = NSRect(x: (canvasSize.width - frameWidth) / 2, y: 60, width: frameWidth, height: frameHeight)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: frame, xRadius: 54, yRadius: 54).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: frame, xRadius: 54, yRadius: 54).addClip()
    image.draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

func drawCropped(_ image: NSImage, in rect: NSRect) {
    let imageRatio = image.size.width / image.size.height
    let rectRatio = rect.width / rect.height
    var source = NSRect(origin: .zero, size: image.size)
    if imageRatio > rectRatio {
        let width = image.size.height * rectRatio
        source.origin.x = (image.size.width - width) / 2
        source.size.width = width
    } else {
        let height = image.size.width / rectRatio
        source.origin.y = (image.size.height - height) / 2
        source.size.height = height
    }
    image.draw(in: rect, from: source, operation: .sourceOver, fraction: 1)
}

try writeCanvas(name: "01-ten-characters.png") {
    drawScreen("\(inputRoot)/01-home.png")
    text("10人の女の子と、本格将棋。", size: isIPad ? 76 : 62, color: darkGreen, y: canvasSize.height - 168)
    text("棋力も作戦も、それぞれ違う。", size: isIPad ? 42 : 34, color: gold, y: canvasSize.height - 240, weight: .semibold)
}

try writeCanvas(name: "02-your-pace.png") {
    drawScreen("\(inputRoot)/02-setup.png")
    text("初心者から、最強まで。", size: isIPad ? 76 : 62, color: darkGreen, y: canvasSize.height - 168)
    text("平手・駒落ち・ヒントで自分のペース。", size: isIPad ? 42 : 34, color: gold, y: canvasSize.height - 240, weight: .semibold)
}

try writeCanvas(name: "03-deepen-bond.png") {
    drawScreen("\(inputRoot)/03-battle.png")
    text("負けても、絆は深まる。", size: isIPad ? 76 : 62, color: darkGreen, y: canvasSize.height - 168)
    text("対局を重ねて、次の相手に出会おう。", size: isIPad ? 42 : 34, color: gold, y: canvasSize.height - 240, weight: .semibold)
}

try writeCanvas(name: "04-reward-gallery.png") {
    text("50枚の特別な思い出。", size: isIPad ? 78 : 64, color: darkGreen, y: canvasSize.height - 176)
    text("勝利を重ねて、特別な姿を解放。", size: isIPad ? 44 : 36, color: gold, y: canvasSize.height - 254, weight: .semibold)
    let names = ["koharu_reward_4", "shion_reward_4", "tsukika_reward_4"]
    let frames: [NSRect] = isIPad ? [
        NSRect(x: 64, y: 180, width: 600, height: 2200),
        NSRect(x: 724, y: 180, width: 600, height: 2200),
        NSRect(x: 1384, y: 180, width: 600, height: 2200)
    ] : [
        NSRect(x: 72, y: 190, width: 520, height: 2100),
        NSRect(x: 650, y: 190, width: 520, height: 2100),
        NSRect(x: 361, y: 440, width: 520, height: 1600)
    ]
    for (index, name) in names.enumerated() {
        guard let image = NSImage(contentsOfFile: projectRoot.appendingPathComponent("App/Resources/Optimized/\(name).jpg").path) else { continue }
        let frame = frames[index]
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
        shadow.shadowBlurRadius = 24
        shadow.shadowOffset = NSSize(width: 0, height: -8)
        shadow.set()
        NSColor.white.setFill()
        NSBezierPath(roundedRect: frame, xRadius: 42, yRadius: 42).fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: frame, xRadius: 42, yRadius: 42).addClip()
        drawCropped(image, in: frame)
        NSGraphicsContext.restoreGraphicsState()
    }
}

try writeCanvas(name: "05-daily-play.png") {
    text("今日も、あなたと一局。", size: isIPad ? 78 : 64, color: darkGreen, y: canvasSize.height - 176)
    text("毎日の目標と、自動保存で続きから。", size: isIPad ? 44 : 36, color: gold, y: canvasSize.height - 254, weight: .semibold)
    let names = ["koharu", "hinata", "chinatsu", "mio", "kotone", "rin", "cecilia", "akane", "shion", "tsukika"]
    let horizontalMargin: CGFloat = isIPad ? 64 : 52
    let gap: CGFloat = isIPad ? 32 : 27
    let cardWidth = (canvasSize.width - horizontalMargin * 2 - gap * 4) / 5
    let cardHeight: CGFloat = isIPad ? 850 : 820
    for (index, name) in names.enumerated() {
        let column = index % 5
        let row = index / 5
        let x = horizontalMargin + CGFloat(column) * (cardWidth + gap)
        let y = (isIPad ? 1370 : 1320) - CGFloat(row) * (isIPad ? 960 : 930)
        let frame = NSRect(x: x, y: y, width: cardWidth, height: cardHeight)
        guard let image = NSImage(contentsOfFile: projectRoot.appendingPathComponent("App/Resources/Optimized/\(name)_base.jpg").path) else { continue }
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: frame, xRadius: 34, yRadius: 34).addClip()
        drawCropped(image, in: frame)
        NSGraphicsContext.restoreGraphicsState()
        let border = NSBezierPath(roundedRect: frame, xRadius: 34, yRadius: 34)
        darkGreen.withAlphaComponent(0.35).setStroke()
        border.lineWidth = 3
        border.stroke()
    }
}

print(outputRoot.path)
