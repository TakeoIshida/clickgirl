import AppKit
// QA-only thumbnail sheets; source images are never changed.
let root = URL(fileURLWithPath:CommandLine.arguments[1])
let files = try FileManager.default.contentsOfDirectory(at:root,includingPropertiesForKeys:nil).filter { $0.pathExtension == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
for start in stride(from:0,to:files.count,by:30) {
    let chunk = Array(files.dropFirst(start).prefix(30)), w = 1200, h = 1500
    let context = CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext:context,flipped:false)
    NSColor.white.setFill(); NSBezierPath(rect:NSRect(x:0,y:0,width:w,height:h)).fill()
    for (i,url) in chunk.enumerated() {
        guard let image = NSImage(contentsOf:url) else { continue }
        let x = CGFloat(i % 6)*200, y = CGFloat(4-i/6)*300
        let scale = min(190/image.size.width,268/image.size.height)
        let size = NSSize(width:image.size.width*scale,height:image.size.height*scale)
        image.draw(in:NSRect(x:x+(200-size.width)/2,y:y+25+(268-size.height)/2,width:size.width,height:size.height))
        (url.deletingPathExtension().lastPathComponent as NSString).draw(at:NSPoint(x:x+5,y:y+5),withAttributes:[.font:NSFont.systemFont(ofSize:12),.foregroundColor:NSColor.black])
    }
    NSGraphicsContext.restoreGraphicsState()
    let dest = URL(fileURLWithPath:CommandLine.arguments[2]+"/art-sheet-\(start/30).png")
    try NSBitmapImageRep(cgImage:context.makeImage()!).representation(using:.png,properties:[:])!.write(to:dest)
    print(dest.path)
}
