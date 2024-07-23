//
//  CodebaseAggregatorViewModel.swift
//  distil-coder
//
//  Created by Kitten Yang on 2024/7/23
//  Copyright (c) 2024 QitaoYang Co., Ltd. All rights reserved.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

class CodebaseAggregatorViewModel: ObservableObject {
	@Published var inputDirectory: String = ""
	@Published var outputFilePath: String = ""
	@Published var useDefaultIgnores: Bool = true
	@Published var removeWhitespace: Bool = false
	@Published var showOutputFiles: Bool = false
	@Published var logOutput: String = ""
	@Published var isProcessing: Bool = false
	@Published var showAlert: Bool = false
	@Published var alertTitle: String = ""
	@Published var alertMessage: String = ""
	@Published var customIgnorePatterns: [String] = []
	@Published var newIgnorePattern: String = ""
	
	private let fileManager = FileManager.default
	private let aggregator = CodebaseAggregator()
	
	func selectInputDirectory() {
		let panel = NSOpenPanel()
		panel.allowsMultipleSelection = false
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		
		if panel.runModal() == .OK {
			self.inputDirectory = panel.url?.path ?? ""
		}
	}
	
	func selectOutputFile() {
		let panel = NSSavePanel()
		if #available(macOS 11.0, *) {
			panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
		} else {
			panel.allowedFileTypes = ["md"]
		}
		panel.nameFieldStringValue = "code_context.md"
		
		if panel.runModal() == .OK {
			self.outputFilePath = panel.url?.path ?? ""
		}
	}
	
	func openOutputFolder() {
		guard !outputFilePath.isEmpty else { return }
		let folderURL = URL(fileURLWithPath: outputFilePath).deletingLastPathComponent()
		NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderURL.path)
	}
	
	func aggregateCodebase() {
		guard !inputDirectory.isEmpty else {
			showAlert(title: "Error", message: "Please select an input directory.")
			return
		}
		
		guard !outputFilePath.isEmpty else {
			showAlert(title: "Error", message: "Please select an output file location.")
			return
		}
		
		isProcessing = true
		logOutput = ""
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				try self.aggregator.aggregateFiles(
					inputDir: self.inputDirectory,
					outputFile: self.outputFilePath,
					useDefaultIgnores: self.useDefaultIgnores,
					removeWhitespaceFlag: self.removeWhitespace,
					showOutputFiles: self.showOutputFiles,
					customIgnorePatterns: self.customIgnorePatterns
				) { log in
					DispatchQueue.main.async {
						self.logOutput += log + "\n"
					}
				}
				
				DispatchQueue.main.async {
					self.isProcessing = false
					self.showAlert(title: "Success", message: "Codebase aggregated successfully. File saved at: \(self.outputFilePath)")
					// 添加1秒延迟后打开文件夹
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
						self.openOutputFolder()
					}
				}
			} catch {
				DispatchQueue.main.async {
					self.isProcessing = false
					self.showAlert(title: "Error", message: error.localizedDescription)
				}
			}
		}
	}
	
	func addIgnorePattern() {
		guard !newIgnorePattern.isEmpty else { return }
		customIgnorePatterns.append(newIgnorePattern)
		newIgnorePattern = ""
	}
	
	
	func removeIgnorePatterns(at offsets: IndexSet) {
		customIgnorePatterns.remove(atOffsets: offsets)
	}
	
	func openOutputFile() {
		NSWorkspace.shared.open(URL(fileURLWithPath: outputFilePath))
	}
	
	private func showAlert(title: String, message: String) {
		self.alertTitle = title
		self.alertMessage = message
		self.showAlert = true
	}
}
