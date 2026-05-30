import Foundation

struct BinaryWriter {
    private(set) var data = Data()

    mutating func uint8(_ value: UInt8) {
        data.append(value)
    }

    mutating func uint16(_ value: UInt16) {
        var bigEndian = value.bigEndian
        withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
    }

    mutating func int16(_ value: Int16) {
        var bigEndian = value.bigEndian
        withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
    }

    mutating func uint32(_ value: UInt32) {
        var bigEndian = value.bigEndian
        withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
    }

    mutating func int32(_ value: Int32) {
        var bigEndian = value.bigEndian
        withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
    }

    mutating func int64(_ value: Int64) {
        var bigEndian = value.bigEndian
        withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
    }

    mutating func fixed32(_ value: Float) {
        let fixed = Int32(value * 65536.0)
        int32(fixed)
    }

    mutating func bytes(_ value: Data) {
        data.append(value)
    }

    mutating func ascii(_ string: String, length: Int) {
        var buffer = Data(repeating: 0, count: length)
        let ascii = Array(string.utf8.prefix(length))
        buffer.replaceSubrange(0 ..< ascii.count, with: ascii)
        data.append(buffer)
    }

    mutating func pad(to alignment: Int) {
        let remainder = data.count % alignment
        guard remainder != 0 else { return }
        data.append(Data(repeating: 0, count: alignment - remainder))
    }
}

struct FontTable {
    let tag: String
    let data: Data
}

enum FontTableChecksum {
    static func checksum(for data: Data) -> UInt32 {
        var sum: UInt32 = 0
        let padded = pad(data, alignment: 4)
        padded.withUnsafeBytes { buffer in
            let count = buffer.count / 4
            for index in 0 ..< count {
                let value = buffer.load(fromByteOffset: index * 4, as: UInt32.self)
                sum = sum &+ value.bigEndian
            }
        }
        return sum
    }

    static func sfntChecksum(tag: String, data: Data) -> UInt32 {
        var sum = checksum(for: data)
        var tagValue: UInt32 = 0
        for byte in tag.utf8.prefix(4) {
            tagValue = (tagValue << 8) | UInt32(byte)
        }
        sum = sum &+ tagValue
        let length = UInt32(data.count)
        sum = sum &+ length
        return sum
    }

    private static func pad(_ data: Data, alignment: Int) -> Data {
        let remainder = data.count % alignment
        guard remainder != 0 else { return data }
        var padded = data
        padded.append(Data(repeating: 0, count: alignment - remainder))
        return padded
    }
}
