import AppKit
// Original vector-style development icon. Does not modify character art.
let output = CommandLine.arguments[1]
let context = CGContext(data:nil,width:1024,height:1024,bitsPerComponent:8,bytesPerRow:4096,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext:context,flipped:false)
NSColor(calibratedRed:0.19,green:0.31,blue:0.25,alpha:1).setFill(); NSBezierPath(rect:NSRect(x:0,y:0,width:1024,height:1024)).fill()
let tile = NSBezierPath(); tile.move(to:NSPoint(x:270,y:180)); tile.line(to:NSPoint(x:754,y:180)); tile.line(to:NSPoint(x:704,y:700)); tile.line(to:NSPoint(x:512,y:836)); tile.line(to:NSPoint(x:320,y:700)); tile.close()
NSColor(calibratedRed:0.93,green:0.79,blue:0.54,alpha:1).setFill(); tile.fill()
let attrs: [NSAttributedString.Key:Any] = [.font:NSFont(name:"HiraMinProN-W6",size:330) ?? NSFont.boldSystemFont(ofSize:330),.foregroundColor:NSColor(calibratedRed:0.2,green:0.25,blue:0.21,alpha:1)]
("王" as NSString).draw(at:NSPoint(x:346,y:295),withAttributes:attrs)
for i in 0..<5 { let angle = CGFloat(i)*2*CGFloat.pi/5; let x = 785+cos(angle)*58, y = 775+sin(angle)*58; NSColor(calibratedRed:0.91,green:0.54,blue:0.56,alpha:1).setFill(); NSBezierPath(ovalIn:NSRect(x:x-40,y:y-40,width:80,height:80)).fill() }
NSColor(calibratedRed:0.98,green:0.86,blue:0.60,alpha:1).setFill(); NSBezierPath(ovalIn:NSRect(x:764,y:754,width:42,height:42)).fill()
NSGraphicsContext.restoreGraphicsState()
try NSBitmapImageRep(cgImage:context.makeImage()!).representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:output))
