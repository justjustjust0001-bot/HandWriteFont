import CoreGraphics
import Foundation

@main
struct VerifyFullFreeExport {
    static func main() {
        let stroke = DrawingStroke(
            points: [
                CGPoint(x: 40, y: 200),
                CGPoint(x: 150, y: 40),
                CGPoint(x: 260, y: 200),
                CGPoint(x: 150, y: 360),
                CGPoint(x: 40, y: 200)
            ],
            strokeWidth: 10
        )
        let canvas = CGSize(width: 300, height: 400)

        let freeString =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
            "abcdefghijklmnopqrstuvwxyz" +
            "0123456789" +
            "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをん" +
            "がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ" +
            "ぁぃぅぇぉゃゅょっゎー" +
            "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲン" +
            "ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ" +
            "ァィゥェォャュョッヮー" +
            "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~" +
            "、。・「」『』（）ー〜…！？‥‘’“”％＃＆＊＋－＝＜＞＠￥"

        var seen = Set<UInt32>()
        var glyphs: [VectorGlyphSource] = []
        for ch in freeString {
            guard let scalar = ch.unicodeScalars.first else { continue }
            if seen.contains(scalar.value) { continue }
            seen.insert(scalar.value)
            glyphs.append(VectorGlyphSource(
                character: ch,
                strokes: [stroke],
                canvasSize: canvas,
                strokeWidth: 10
            ))
        }

        print("building vector font with", glyphs.count, "glyphs…")

        do {
            let data = try VectorFontBuilder.build(
                fontName: "CmapFixVerify",
                disambiguator: "VERIFY01",
                glyphs: glyphs
            )
            let url = URL(fileURLWithPath: "/tmp/fontmaker-cmap-fix-verify.ttf")
            try data.write(to: url)
            print("OK vector bytes:", data.count, "->", url.path)

            let cmap = OpenTypeTables.makeCmapTable(codepoints: glyphs.map {
                Int($0.character.unicodeScalars.first!.value)
            })
            print("OK cmap table bytes:", cmap.count)

            let dangerChars: [Character] = Array("！？％＃＆＊＋－＝＜＞＠（）￥")
            let dangerGlyphs = dangerChars.map {
                VectorGlyphSource(character: $0, strokes: [stroke], canvasSize: canvas, strokeWidth: 10)
            }
            let dangerData = try VectorFontBuilder.build(
                fontName: "DangerSymbols",
                disambiguator: "DANGER01",
                glyphs: dangerGlyphs
            )
            print("OK danger-only font bytes:", dangerData.count, "glyphs:", dangerGlyphs.count)

            // Hiragana-only (user said this still failed when symbols present in project —
            // but hiragana alone should always have worked)
            let kana = Array("あいうえおかきくけこ").map {
                VectorGlyphSource(character: $0, strokes: [stroke], canvasSize: canvas, strokeWidth: 10)
            }
            let kanaData = try VectorFontBuilder.build(
                fontName: "KanaOnly",
                disambiguator: "KANA0001",
                glyphs: kana
            )
            print("OK kana-only font bytes:", kanaData.count)

            print("PASS: full free set + danger-only + kana-only vector export completed without trap")
        } catch {
            fputs("FAIL: \(error)\n", stderr)
            exit(1)
        }
    }
}
