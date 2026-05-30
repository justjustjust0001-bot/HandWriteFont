import Foundation

enum TrueTypeFontAssembler {
    static func assemble(tables: [FontTable]) -> Data {
        let numTables = UInt16(tables.count)
        let entrySelector = UInt16(floor(log2(Double(numTables))))
        let searchRange = UInt16((1 << Int(entrySelector)) * 16)
        let rangeShift = numTables * 16 &- searchRange

        var tableRecords = BinaryWriter()
        var tableData = Data()
        var offset: UInt32 = 12 + UInt32(numTables) * 16

        for table in tables.sorted(by: { $0.tag < $1.tag }) {
            let unpadded = table.data
            let padded = pad(unpadded)
            let checksum = FontTableChecksum.sfntChecksum(tag: table.tag, data: padded)
            tableRecords.ascii(table.tag, length: 4)
            tableRecords.uint32(checksum)
            tableRecords.uint32(offset)
            tableRecords.uint32(UInt32(unpadded.count))
            tableData.append(padded)
            offset += UInt32(padded.count)
        }

        var writer = BinaryWriter()
        writer.uint32(0x00010000)
        writer.uint16(numTables)
        writer.uint16(searchRange)
        writer.uint16(entrySelector)
        writer.uint16(rangeShift)
        writer.bytes(tableRecords.data)
        writer.bytes(tableData)

        var fontData = writer.data
        patchHeadChecksumAdjustment(in: &fontData)
        return fontData
    }

    static func pad(_ data: Data) -> Data {
        let remainder = data.count % 4
        guard remainder != 0 else { return data }
        var padded = data
        padded.append(Data(repeating: 0, count: 4 - remainder))
        return padded
    }

    private static func patchHeadChecksumAdjustment(in fontData: inout Data) {
        guard fontData.count > 12 else { return }
        let tableCount = Int(readUInt16(from: fontData, at: 4))
        var headOffset: Int?
        for index in 0 ..< tableCount {
            let recordOffset = 12 + index * 16
            let tag = String(bytes: fontData[recordOffset ..< recordOffset + 4], encoding: .ascii)
            if tag == "head" {
                headOffset = Int(readUInt32(from: fontData, at: recordOffset + 8))
                break
            }
        }
        guard let headOffset else { return }

        var fullSum: UInt32 = 0
        let paddedFont = pad(fontData)
        paddedFont.withUnsafeBytes { buffer in
            let count = buffer.count / 4
            for index in 0 ..< count {
                let value = buffer.load(fromByteOffset: index * 4, as: UInt32.self)
                fullSum = fullSum &+ value.bigEndian
            }
        }
        let adjustment = 0xB1B0_AF_BA &- fullSum
        var bigEndian = adjustment.bigEndian
        withUnsafeBytes(of: &bigEndian) { bytes in
            fontData.replaceSubrange(headOffset + 8 ..< headOffset + 12, with: bytes)
        }
    }

    private static func readUInt16(from data: Data, at offset: Int) -> UInt16 {
        data.withUnsafeBytes { buffer in
            UInt16(bigEndian: buffer.load(fromByteOffset: offset, as: UInt16.self))
        }
    }

    private static func readUInt32(from data: Data, at offset: Int) -> UInt32 {
        data.withUnsafeBytes { buffer in
            UInt32(bigEndian: buffer.load(fromByteOffset: offset, as: UInt32.self))
        }
    }
}
