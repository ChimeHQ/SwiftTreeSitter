#if !os(WASI)
import Foundation
import TestTreeSitterSwift
import SwiftTreeSitter
import XCTest

final class LanguageTests: XCTestCase {
    private let fileManager = FileManager.default

    func testFileFoundInBundle() throws {
        let filename = "highlights.scm"
        let bundlePath = "Swift.bundle/Contents/Resources/queries"
        try setupFile(filename, in: bundlePath)

        let language = Language(
            language: tree_sitter_swift(),
            name: "Swift"
        )
        XCTAssertNotNil(language.highlightsFileURL)

        try removeFile(filename, in: bundlePath)
    }

    func testFileFoundInResourceDir() throws {
        let filename = "injections.scm"
        let dirPath = "Markdown/queries"
        try setupFile(filename, in: dirPath)

        let language = Language(
            language: tree_sitter_swift(),
            name: "Markdown"
        )
        XCTAssertNotNil(language.injectionsFileURL)

        try removeFile(filename, in: dirPath)
    }

    func testMatchHappensWhenMultiplePathsShareCommonName() throws {
        let filename = "injections.scm"
        let jsonDirPath = "JSON/queries"
        let json5DirPath = "JSON5/queries"
        try setupFile(filename, in: jsonDirPath)
        try setupFile(filename, in: json5DirPath)

        let language = Language(
            language: tree_sitter_swift(),
            name: "JSON"
        )

		let url = try XCTUnwrap(language.injectionsFileURL)

        XCTAssertTrue(url.absoluteString.contains("JSON/queries"))

        try removeFile(filename, in: jsonDirPath)
        try removeFile(filename, in: json5DirPath)
    }

    private func setupFile(_ filename: String, in directoryPath: String) throws {
        let dir = Bundle.test.bundlePath.appending("/\(directoryPath)")
        let filePath = "\(dir)/\(filename)"

        if fileManager.fileExists(atPath: dir, isDirectory: nil) == false {
            try fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }

        if fileManager.createFile(atPath: filePath, contents: nil) == false {
            XCTFail("could not write file")
        }
    }

    private func removeFile(_ filename: String, in directoryPath: String) throws {
        let filePath = Bundle.test.bundlePath.appending("/\(directoryPath)/\(filename)")
        try fileManager.removeItem(atPath: filePath)
    }
}

private extension Bundle {
    static var test: Bundle {
        return Bundle.allBundles
            .first(where: { $0.bundlePath.components(separatedBy: "/")
                .last!
                .contains("Tests.xctest") == true }
            )!
    }
}
#endif
