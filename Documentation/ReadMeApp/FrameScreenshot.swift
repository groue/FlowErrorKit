// Draws a Simulator screenshot inside the Simulator device bezel.
//
// Usage: swift FrameScreenshot.swift <device-type-name> <screenshot.png> <output.png>
//
// For example:
//
//     xcrun simctl io booted screenshot raw.png
//     swift FrameScreenshot.swift "iPhone 13 mini" raw.png framed.png
//
// The device type name is the one listed by `xcrun simctl list devicetypes`.
import AppKit

let args = CommandLine.arguments
let deviceTypeName = args[1]
let screenshot = NSImage(contentsOfFile: args[2])!
let outputURL = URL(fileURLWithPath: args[3])

let deviceType = "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/\(deviceTypeName).simdevicetype/Contents/Resources"
let profile = NSDictionary(contentsOfFile: "\(deviceType)/profile.plist")!
let chromeID = (profile["chromeIdentifier"] as! String).components(separatedBy: ".").last!
let chrome = "/Library/Developer/DeviceKit/Chrome/\(chromeID).devicechrome/Contents/Resources"
let json = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: "\(chrome)/chrome.json"))) as! [String: Any]
let images = json["images"] as! [String: Any]
let sizing = images["sizing"] as! [String: Double]
let padding = images["devicePadding"] as! [String: Double]

func pdf(_ name: String) -> NSImage { NSImage(contentsOfFile: "\(chrome)/\(name).pdf")! }
func image(_ key: String) -> NSImage { pdf(images[key] as! String) }

// Geometry, in points.
//
// The output has the pixel density of the screenshot, and the screenshot
// is copied pixel for pixel, at a whole-pixel offset. The chrome is vector
// art, sharp at any density.
let mask = NSImage(contentsOfFile: "\(deviceType)/\(profile["framebufferMask"] as! String).pdf")!
let pixelsWide = Double(screenshot.representations[0].pixelsWide)
let pixelsHigh = Double(screenshot.representations[0].pixelsHigh)
let scale = pixelsWide / (mask.size.width / 3) // The mask is drawn at 3x.
let screenSize = CGSize(width: pixelsWide / scale, height: pixelsHigh / scale)

func snapped(_ points: Double) -> Double { (points * scale).rounded(.up) / scale }
let screenOrigin = CGPoint(
    x: snapped(padding["left"]! + sizing["leftWidth"]!),
    y: snapped(padding["top"]! + sizing["topHeight"]!))
let frameRect = CGRect(
    x: screenOrigin.x - sizing["leftWidth"]!, y: screenOrigin.y - sizing["topHeight"]!,
    width: screenSize.width + sizing["leftWidth"]! + sizing["rightWidth"]!,
    height: screenSize.height + sizing["topHeight"]! + sizing["bottomHeight"]!)
let screenRect = CGRect(origin: screenOrigin, size: screenSize)
let canvasSize = CGSize(
    width: snapped(frameRect.maxX + padding["right"]!),
    height: snapped(frameRect.maxY + padding["bottom"]!))

/// Returns a bitmap of the given size, and makes it the current context,
/// with a top-left origin.
func makeBitmap(size: CGSize, scale: Double) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int((size.width * scale).rounded()),
        pixelsHigh: Int((size.height * scale).rounded()),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    let cg = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    cg.translateBy(x: 0, y: size.height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    return rep
}

func draw(_ img: NSImage, in rect: CGRect) {
    img.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
}

// The chrome is drawn in its own layer, with the geometry of the Simulator
// (whole points), at 3x: this is how its pieces meet on whole pixels,
// without seams. The layer is then scaled into the output.
let chromeFrame = CGRect(
    x: padding["left"]!, y: padding["top"]!,
    width: mask.size.width / 3 + sizing["leftWidth"]! + sizing["rightWidth"]!,
    height: mask.size.height / 3 + sizing["topHeight"]! + sizing["bottomHeight"]!)
let chromeSize = CGSize(
    width: chromeFrame.maxX + padding["right"]!,
    height: chromeFrame.maxY + padding["bottom"]!)
let chromeBitmap = makeBitmap(size: chromeSize, scale: 3)

// Buttons, behind the frame.
for input in json["inputs"] as! [[String: Any]] where (input["onTop"] as? Bool) != true {
    let img = pdf(input["image"] as! String)
    let offset = (input["offsets"] as! [String: [String: Double]])["normal"]!
    let x = input["anchor"] as! String == "left"
        ? chromeFrame.minX - img.size.width + offset["x"]!
        : chromeFrame.maxX + offset["x"]!
    draw(img, in: CGRect(x: x, y: chromeFrame.minY + offset["y"]!, width: img.size.width, height: img.size.height))
}

// Frame: nine-slice.
let corner = image("topLeft").size
draw(image("topLeft"), in: CGRect(origin: chromeFrame.origin, size: corner))
draw(image("topRight"), in: CGRect(x: chromeFrame.maxX - corner.width, y: chromeFrame.minY, width: corner.width, height: corner.height))
draw(image("bottomLeft"), in: CGRect(x: chromeFrame.minX, y: chromeFrame.maxY - corner.height, width: corner.width, height: corner.height))
draw(image("bottomRight"), in: CGRect(x: chromeFrame.maxX - corner.width, y: chromeFrame.maxY - corner.height, width: corner.width, height: corner.height))
draw(image("top"), in: CGRect(x: chromeFrame.minX + corner.width, y: chromeFrame.minY, width: chromeFrame.width - 2 * corner.width, height: corner.height))
draw(image("bottom"), in: CGRect(x: chromeFrame.minX + corner.width, y: chromeFrame.maxY - corner.height, width: chromeFrame.width - 2 * corner.width, height: corner.height))
draw(image("left"), in: CGRect(x: chromeFrame.minX, y: chromeFrame.minY + corner.height, width: corner.width, height: chromeFrame.height - 2 * corner.height))
draw(image("right"), in: CGRect(x: chromeFrame.maxX - corner.width, y: chromeFrame.minY + corner.height, width: corner.width, height: chromeFrame.height - 2 * corner.height))

// The output, at the density of the screenshot.
let rep = makeBitmap(size: canvasSize, scale: scale)
NSGraphicsContext.current!.imageInterpolation = .high
let chromeImage = NSImage(size: chromeSize)
chromeImage.addRepresentation(chromeBitmap)
draw(chromeImage, in: CGRect(
    x: frameRect.minX - padding["left"]!, y: frameRect.minY - padding["top"]!,
    width: frameRect.width + padding["left"]! + padding["right"]!,
    height: frameRect.height + padding["top"]! + padding["bottom"]!))

// Screen, clipped by the framebuffer mask (rounded corners, sensor housing).
let screenLayer = NSImage(size: screenSize, flipped: false) { rect in
    screenshot.draw(in: rect)
    mask.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
    return true
}
NSGraphicsContext.current!.imageInterpolation = .none
draw(screenLayer, in: screenRect)
NSGraphicsContext.current!.imageInterpolation = .high

// Sensor housing (notch or Dynamic Island), centered at the top of the screen.
if let name = profile["sensorBarImage"] as? String,
   let sensorBar = NSImage(contentsOfFile: "\(deviceType)/\(name).pdf")
{
    // Painted black, like the real hardware.
    let black = NSImage(size: sensorBar.size, flipped: false) { rect in
        sensorBar.draw(in: rect)
        NSColor.black.set()
        rect.fill(using: .sourceAtop)
        return true
    }
    draw(black, in: CGRect(
        x: screenRect.midX - sensorBar.size.width / 2, y: screenRect.minY,
        width: sensorBar.size.width, height: sensorBar.size.height))
}

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: outputURL)
