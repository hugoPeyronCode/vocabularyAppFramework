// Habille une capture brute pour l'App Store : fond du design system, titre en haut, capture aux coins arrondis.
// Usage : swift Scripts/frame_screenshots.swift <capture.png> <sortie.png> <light|dark> "<titre>"
import AppKit
import CoreText

let arguments = CommandLine.arguments
guard arguments.count == 5, let source = NSImage(contentsOfFile: arguments[1]),
      let screenshot = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write(Data("usage : frame_screenshots.swift <capture.png> <sortie.png> <light|dark> <titre>\n".utf8))
    exit(1)
}
let isDark = arguments[3] == "dark"
let title = arguments[4]

// 6,9 pouces (iPhone 17 Pro Max), portrait.
let width = 1320, height = 2868
// Tokens `background` et `textPrimary` de SagaceUI.
func rgb(_ hex: Int) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}
let background = rgb(isDark ? 0x181818 : 0xE0E0E0)
let ink = rgb(isDark ? 0xFDFDFD : 0x181818)

let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { exit(1) }
context.setFillColor(background)
context.fill(CGRect(x: 0, y: 0, width: width, height: height))

// Titre : gras, centré, deux lignes au plus, dans les 520 px du haut.
let font = CTFontCreateUIFontForLanguage(.system, 104, "fr" as CFString).flatMap { CTFontCreateCopyWithSymbolicTraits($0, 104, nil, .traitBold, .traitBold) }
    ?? CTFontCreateWithName("Helvetica-Bold" as CFString, 104, nil)
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
paragraph.lineHeightMultiple = 0.95
let attributed = NSAttributedString(string: title, attributes: [
    .font: font, .foregroundColor: NSColor(cgColor: ink)!, .paragraphStyle: paragraph,
])
let framesetter = CTFramesetterCreateWithAttributedString(attributed)
let textBox = CGRect(x: 100, y: height - 540, width: width - 200, height: 400)
let fitted = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, textBox.size, nil)
let textRect = CGRect(x: textBox.minX, y: textBox.minY + (textBox.height - fitted.height) / 2, width: textBox.width, height: fitted.height)
CTFrameDraw(CTFramesetterCreateFrame(framesetter, CFRange(), CGPath(rect: textRect, transform: nil), nil), context)

// Capture réduite à 78 %, coins arrondis comme l'écran de l'iPhone.
let scale = 0.78
let shotSize = CGSize(width: CGFloat(width) * scale, height: CGFloat(height) * scale)
let shotRect = CGRect(x: (CGFloat(width) - shotSize.width) / 2, y: 80, width: shotSize.width, height: shotSize.height)
let corner: CGFloat = 130
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -12), blur: 60, color: CGColor(gray: 0, alpha: isDark ? 0.5 : 0.18))
context.addPath(CGPath(roundedRect: shotRect, cornerWidth: corner, cornerHeight: corner, transform: nil))
context.setFillColor(background)
context.fillPath()
context.restoreGState()
context.saveGState()
context.addPath(CGPath(roundedRect: shotRect, cornerWidth: corner, cornerHeight: corner, transform: nil))
context.clip()
context.interpolationQuality = .high
context.draw(screenshot, in: shotRect)
context.restoreGState()

guard let image = context.makeImage(),
      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: arguments[2]))
