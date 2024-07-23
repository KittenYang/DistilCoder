//
//  CodebaseAggregator.swift
//  distil-coder
//
//  Created by Kitten Yang on 2024/7/23
//  Copyright (c) 2024 QitaoYang Co., Ltd. All rights reserved.
//
    

import Foundation

class CodebaseAggregator {
	private let fileManager = FileManager.default
	
	func aggregateFiles(
		inputDir: String,
		outputFile: String,
		useDefaultIgnores: Bool,
		removeWhitespaceFlag: Bool,
		showOutputFiles: Bool,
		customIgnorePatterns: [String],
		logHandler: @escaping (String) -> Void
	) throws {
		let inputURL = URL(fileURLWithPath: inputDir)
		var output = ""
		var includedFiles: [String] = []
		
		let aidigestignorePatterns = try readAidigestignore(inputDir: inputDir)
		let ignorePatterns = (useDefaultIgnores ? DEFAULT_IGNORES : []) + customIgnorePatterns + aidigestignorePatterns
		
		logHandler("Starting file aggregation...")
		logHandler("Input directory: \(inputDir)")
		logHandler("Output file: \(outputFile)")
		logHandler("Using \(ignorePatterns.count) ignore patterns")
		
		let enumerator = fileManager.enumerator(at: inputURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
		
		while let fileURL = enumerator?.nextObject() as? URL {
			let relativePath = fileURL.relativePath(from: inputURL)
			
			if !shouldIgnoreFile(relativePath: relativePath, ignorePatterns: ignorePatterns) {
				if let content = try? String(contentsOf: fileURL) {
					output += "# \(relativePath)\n\n"
					output += "```\(fileURL.pathExtension)\n"
					if removeWhitespaceFlag && !isWhitespaceSensitiveFile(fileURL) {
						output += removeWhitespace(content)
					} else {
						output += content
					}
					output += "\n```\n\n"
					includedFiles.append(relativePath)
					logHandler("Processed: \(relativePath)")
				} else {
					output += "# \(relativePath)\n\n"
					output += "This is a binary file.\n\n"
					includedFiles.append(relativePath)
					logHandler("Included binary file: \(relativePath)")
				}
			} else {
				logHandler("Ignored: \(relativePath)")
			}
		}
		
		try output.write(toFile: outputFile, atomically: true, encoding: .utf8)
		
		logHandler("Files aggregated successfully.")
		logHandler("Total files included: \(includedFiles.count)")
		
		if showOutputFiles {
			logHandler("Included files:")
			includedFiles.forEach { logHandler("- \($0)") }
		}
	}
	
	private func isWhitespaceSensitiveFile(_ fileURL: URL) -> Bool {
		let whitespaceSensitiveExtensions = ["py", "yaml", "yml", "md", "swift", "go"]
		return whitespaceSensitiveExtensions.contains(fileURL.pathExtension.lowercased())
	}
	
	private func readAidigestignore(inputDir: String) throws -> [String] {
		let aidigestignorePath = (inputDir as NSString).appendingPathComponent(".aidigestignore")
		if fileManager.fileExists(atPath: aidigestignorePath) {
			let content = try String(contentsOfFile: aidigestignorePath, encoding: .utf8)
			return content.components(separatedBy: .newlines).filter { !$0.isEmpty && !$0.hasPrefix("#") }
		}
		return []
	}
	
	private func shouldIgnoreFile(relativePath: String, ignorePatterns: [String]) -> Bool {
		for pattern in ignorePatterns {
			if relativePath.contains(pattern) || relativePath.matches(pattern: pattern) {
				return true
			}
		}
		return false
	}
	
	private func removeWhitespace(_ content: String) -> String {
		return content.split(omittingEmptySubsequences: false) { $0.isNewline }
			.map { line -> String in
				let trimmed = line.trimmingCharacters(in: .whitespaces)
				if trimmed.isEmpty {
					return ""
				} else {
					// 计算前导空格和制表符
					let leadingWhitespace = line.prefix(while: { $0 == " " || $0 == "\t" })
					return leadingWhitespace + trimmed
				}
			}
			.joined(separator: "\n")
	}
}

extension URL {
	func relativePath(from base: URL) -> String {
		let pathComponents = self.pathComponents
		let basePathComponents = base.pathComponents
		
		var i = 0
		while i < pathComponents.count && i < basePathComponents.count && pathComponents[i] == basePathComponents[i] {
			i += 1
		}
		
		return pathComponents[i...].joined(separator: "/")
	}
}

extension String {
	func matches(pattern: String) -> Bool {
		let regex = try? NSRegularExpression(pattern: pattern.replacingOccurrences(of: "*", with: ".*"), options: [])
		let range = NSRange(location: 0, length: self.utf16.count)
		return regex?.firstMatch(in: self, options: [], range: range) != nil
	}
}

let DEFAULT_IGNORES = [
	"node_modules",
	".git",
	"build",
	"dist",
	".DS_Store",
	"Thumbs.db",
	".env"
]
