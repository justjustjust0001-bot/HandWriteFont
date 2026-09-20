import Foundation

@main
struct VerifyCmapFromSource {
    static func main() {
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

        var seen = Set<Int>()
        var codepoints: [Int] = []
        for ch in freeString {
            guard let v = ch.unicodeScalars.first.map({ Int($0.value) }) else { continue }
            if seen.insert(v).inserted {
                codepoints.append(v)
            }
        }
        // Same order VectorFontBuilder uses: sorted by codepoint
        codepoints.sort()

        print("calling OpenTypeTables.makeCmapTable with", codepoints.count, "codepoints…")

        // This is the exact call site that previously trapped.
        let cmap = OpenTypeTables.makeCmapTable(codepoints: codepoints)
        print("OK cmap bytes:", cmap.count)

        let dangerOnly = [0xFF01, 0xFF1F, 0xFF05, 0xFF03, 0xFF06, 0xFF0A, 0xFF0B, 0xFF0D, 0xFF1D, 0xFF1C, 0xFF1E, 0xFF20, 0xFF08, 0xFF09, 0xFFE5]
        let dangerCmap = OpenTypeTables.makeCmapTable(codepoints: dangerOnly)
        print("OK danger-only cmap bytes:", dangerCmap.count)

        // Also stress hmtx bearings path with extreme metrics (related hardening)
        let extreme = EncodedGlyphMetrics.encode(contours: [[
            FontPoint(x: Int16.min, y: Int16.min),
            FontPoint(x: Int16.max, y: Int16.max),
            FontPoint(x: 0, y: 0)
        ]])
        let hhea = OpenTypeTables.makeHheaTable(glyphCount: 2, metrics: [
            EncodedGlyphMetrics.encode(contours: []),
            extreme
        ])
        print("OK hhea with extreme metrics bytes:", hhea.count)

        print("PASS: real OpenTypeTables.makeCmapTable survived full free set + danger symbols")
    }
}
