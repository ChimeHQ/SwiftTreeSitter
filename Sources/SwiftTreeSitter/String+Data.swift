import Foundation

extension String {
    static var nativeUTF16Encoding: String.Encoding {
        let dataA = "abc".data(using: .utf16LittleEndian)
        let dataB = "abc".data(using: .utf16)?.suffix(from: 2)

        return dataA == dataB ? .utf16LittleEndian : .utf16BigEndian
    }

    func data(at byteOffset: Int, limit: Int, using encoding: String.Encoding, chunkSize: Int) -> Data? {
        precondition(encoding.internalEncoding != nil)
        
        let location = byteOffset / 2

        let end = min(location + (chunkSize / 2), limit)

        if location > end {
            assertionFailure("location is greater than end")
            return nil
        }

        let range = NSRange(location..<end)
        guard let stringRange = Range(range, in: self) else {
            return nil
        }

        let substring = self[stringRange]

        // have to remove the bom from the string
        return substring.data(using: encoding)
    }
}
