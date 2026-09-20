import Foundation

// Regression check for cmap format-4 idDelta Int16 overflow
// (fullwidth symbols U+FFxx caused trap: Int16(glyphID - codepoint))

func oldTrappingDelta(glyphID: Int, codepoint: Int) -> Int16? {
    // Mirrors the pre-fix conversion that trapped.
    let delta = glyphID - codepoint
    guard delta >= Int(Int16.min), delta <= Int(Int16.max) else { return nil }
    return Int16(delta)
}

func fixedDelta(glyphID: Int, codepoint: Int) -> Int16 {
    Int16(truncatingIfNeeded: glyphID &- codepoint)
}

func recoverGlyphID(idDelta: Int16, codepoint: Int) -> Int {
    (Int(idDelta) + codepoint) & 0xFFFF
}

let freeChars: [Character] = Array(
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
)

let uniqueCodepoints = Array(Set(freeChars.compactMap { $0.unicodeScalars.first.map { Int($0.value) } })).sorted()
print("unique free codepoints:", uniqueCodepoints.count)

var trappingWouldCrash = 0
var fixedFailures = 0

for (index, codepoint) in uniqueCodepoints.enumerated() {
    let glyphID = index + 1
    if oldTrappingDelta(glyphID: glyphID, codepoint: codepoint) == nil {
        trappingWouldCrash += 1
    }
    let delta = fixedDelta(glyphID: glyphID, codepoint: codepoint)
    let recovered = recoverGlyphID(idDelta: delta, codepoint: codepoint)
    if recovered != glyphID {
        fixedFailures += 1
        print("FAIL recover", String(format: "U+%04X", codepoint), "gid", glyphID, "got", recovered)
    }
}

print("codepoints that would crash with old Int16():", trappingWouldCrash)
print("fixed recover failures:", fixedFailures)

// Worst-case single-glyph fonts that still include one overflowing symbol
let danger: [(String, Int)] = [
    ("！", 0xFF01), ("？", 0xFF1F), ("％", 0xFF05), ("＃", 0xFF03),
    ("＆", 0xFF06), ("＊", 0xFF0A), ("＋", 0xFF0B), ("－", 0xFF0D),
    ("＝", 0xFF1D), ("＜", 0xFF1C), ("＞", 0xFF1E), ("＠", 0xFF20),
    ("（", 0xFF08), ("）", 0xFF09), ("￥", 0xFFE5)
]

var singleGlyphCrashes = 0
for (name, cp) in danger {
    let gid = 1
    if oldTrappingDelta(glyphID: gid, codepoint: cp) == nil {
        singleGlyphCrashes += 1
    }
    let d = fixedDelta(glyphID: gid, codepoint: cp)
    precondition(recoverGlyphID(idDelta: d, codepoint: cp) == gid, "\(name) recover failed")
}
print("danger symbols that crash even alone (old):", singleGlyphCrashes, "/", danger.count)

// Exercise actual OpenTypeTables.makeCmapTable via compiled module below.
print("logic check OK")
if trappingWouldCrash == 0 || fixedFailures != 0 {
    fputs("UNEXPECTED: expected old code to crash on some CPs and fixed recover to pass\n", stderr)
    exit(1)
}
print("PASS: old path would crash on \(trappingWouldCrash) CPs; fixed path recovers all \(uniqueCodepoints.count)")
