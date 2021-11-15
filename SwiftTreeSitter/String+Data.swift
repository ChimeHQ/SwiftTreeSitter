import Foundation

public extension StringProtocol {
    func utf16DataWithoutBOM() -> Data? {
        return data(using: .utf16)?.suffix(from: 2)
    }
}

public extension String {
    func utf16Data(at byteOffset: Int, limit: Int, chunkSize: Int = 2048) -> Data? {
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
        return substring.utf16DataWithoutBOM()
    }
}
