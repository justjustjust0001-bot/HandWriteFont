import CoreGraphics
import CoreText
import Foundation

// Smoke test: build a minimal vector font and validate with CoreText + fonttools (external)

let strokes: [DrawingStroke] = [
    DrawingStroke(
        points: [
            CGPoint(x: 50, y: 200),
            CGPoint(x: 150, y: 50),
            CGPoint(x: 250, y: 200),
            CGPoint(x: 150, y: 350),
            CGPoint(x: 50, y: 200)
        ],
        strokeWidth: 8
    )
]

let canvasSize = CGSize(width: 300, height: 300)
let source = VectorGlyphSource(
    character: "A",
    strokes: strokes,
    canvasSize: canvasSize,
    strokeWidth: 8
)

do {
    let data = try VectorFontBuilder.build(
        fontName: "TestFont",
        disambiguator: "SMOKETST",
        glyphs: [source]
    )
    let url = URL(fileURLWithPath: "/tmp/fontmaker-smoke.ttf")
    try data.write(to: url)

    var cgFontOK = false
    if let provider = CGDataProvider(url: url as CFURL), let cgFont = CGFont(provider) {
        cgFontOK = true
        print("CGFont OK:", cgFont.postScriptName as String? ?? "?")
    } else {
        print("CGFont FAILED")
    }

    if let descs = CTFontManagerCreateFontDescriptorsFromData(data as CFData) as? [CTFontDescriptor],
       let first = descs.first {
        let ctFont = CTFontCreateWithFontDescriptor(first, 0, nil)
        print("CTFontDescriptor OK:", CTFontCopyPostScriptName(ctFont) as String? ?? "?")
    } else {
        print("CTFontDescriptor FAILED")
    }

    print("Wrote", url.path, "size", data.count, "cgFont", cgFontOK)
} catch {
    print("BUILD ERROR:", error)
    exit(1)
}
