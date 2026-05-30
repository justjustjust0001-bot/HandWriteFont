import CoreText
import Foundation
import UIKit

@main
enum TestSbixGen {
    static func main() {
        let size = CGSize(width: 128, height: 128)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setStroke()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 30, y: 100))
            path.addLine(to: CGPoint(x: 64, y: 20))
            path.addLine(to: CGPoint(x: 98, y: 100))
            path.lineWidth = 6
            path.stroke()
        }

        guard
            let png = SbixFontBuilder.normalizedPNGData(from: image),
            let fontData = try? SbixFontBuilder.build(
                fontName: "TestFont",
                disambiguator: "TEST",
                glyphs: [
                    FontGlyphSource(character: "A", pngData: png),
                    FontGlyphSource(character: "あ", pngData: png)
                ]
            )
        else {
            fputs("build failed\n", stderr)
            exit(1)
        }

        let out = URL(fileURLWithPath: "/tmp/fontmaker-test-bitmap.ttf")
        try? fontData.write(to: out)

        guard
            let provider = CGDataProvider(data: fontData as CFData),
            let cgFont = CGFont(provider)
        else {
            fputs("CGFont parse failed\n", stderr)
            exit(2)
        }

        var error: Unmanaged<CFError>?
        let registered = CTFontManagerRegisterGraphicsFont(cgFont, &error)
        if !registered {
            let message = error?.takeRetainedValue().localizedDescription ?? "unknown"
            fputs("CTFontManagerRegisterGraphicsFont failed: \(message)\n", stderr)
            exit(3)
        }

        defer { CTFontManagerUnregisterGraphicsFont(cgFont, nil) }

        let postScriptName = cgFont.postScriptName as String? ?? "TestFont-Regular"
        let ctFont = CTFontCreateWithName(postScriptName as CFString, 48, nil)
        let glyphs: [UniChar] = Array("Aあ".utf16)
        var glyphIDs = [CGGlyph](repeating: 0, count: glyphs.count)
        guard CTFontGetGlyphsForCharacters(ctFont, glyphs, &glyphIDs, glyphs.count) else {
            fputs("glyph mapping failed\n", stderr)
            exit(4)
        }

        print("OK \(out.path) ps=\(postScriptName) glyphs=\(glyphIDs)")
    }
}
