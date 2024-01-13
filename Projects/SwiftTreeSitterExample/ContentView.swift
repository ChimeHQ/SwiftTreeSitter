import SwiftUI

import SwiftTreeSitter
import SwiftTreeSitterLayer
import TreeSitterMarkdown
import TreeSitterMarkdownInline
import TreeSitterSwift

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
		.onAppear {
			do {
//				try runTreeSitterTest()
				try runTreeSitterDocumentTest()
			} catch {
				print("error: ", error)
			}
		}
    }

	func runTreeSitterTest() throws {
		let swiftConfig = try LanguageConfiguration(tree_sitter_swift(), name: "Swift")

		let parser = Parser()
		try parser.setLanguage(swiftConfig.language)

		let input = """
func main() {}
"""
		let tree = parser.parse(input)!

		let query = swiftConfig.queries[.highlights]!

		let cursor = query.execute(in: tree)
		let highlights = cursor
			.resolve(with: .init(string: input))
			.highlights()

		for namedRange in highlights {
			print("range: ", namedRange)
		}
	}

	func runTreeSitterDocumentTest() throws {
		let markdownConfig = try LanguageConfiguration(tree_sitter_markdown(), name: "Markdown")
		let markdownInlineConfig = try LanguageConfiguration(
			tree_sitter_markdown_inline(),
			name: "MarkdownInline",
			bundleName: "TreeSitterMarkdown_TreeSitterMarkdownInline"
		)
		let swiftConfig = try LanguageConfiguration(tree_sitter_swift(), name: "Swift")

		let config = LanguageLayer.Configuration(
			languageProvider: {
				name in
				switch name {
				case "markdown":
					return markdownConfig
				case "markdown_inline":
					return markdownInlineConfig
				case "swift":
					return swiftConfig
				default:
					return nil
				}
			}
		)

		let rootLayer = try! LanguageLayer(languageConfig: markdownConfig, configuration: config)

		let source = """
# this is markdown

```swift
func main(a: Int) {
}
```

## also markdown

```swift
let value = "abc"
```
"""

		rootLayer.replaceContent(with: source)

		let fullRange = NSRange(source.startIndex..<source.endIndex, in: source)

		let membershipProvider: SwiftTreeSitter.Predicate.GroupMembershipProvider = { query, range, _ in
			guard query == "local" else { return false }

			return false
		}

		let context = Predicate.Context(textProvider: source.predicateTextProvider, groupMembershipProvider: membershipProvider)

		let provider = source.predicateTextProvider
		let highlights = try rootLayer.highlights(in: fullRange, provider: provider)

		for namedRange in highlights {
			print("\(namedRange.name): \(namedRange.range)")
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
