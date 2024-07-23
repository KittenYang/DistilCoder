//
//  ContentView.swift
//  distil-coder
//
//  Created by Kitten Yang on 2024/7/23
//  Copyright (c) 2024 QitaoYang Co., Ltd. All rights reserved.
//
    

import SwiftUI
import AppKit

struct ContentView: View {
	@StateObject private var viewModel = CodebaseAggregatorViewModel()
	
	var body: some View {
		VStack(spacing: 20) {
			inputSection
			outputSection
			optionsSection
			ignoreFilesSection
			executeButton
			logOutputSection
		}
		.padding()
		.frame(minWidth: 600, minHeight: 700)
		.alert(isPresented: $viewModel.showAlert) {
			Alert(
				title: Text(viewModel.alertTitle),
				message: Text(viewModel.alertMessage),
				primaryButton: .default(Text("OK")),
				secondaryButton: .default(Text("Open File")) {
					viewModel.openOutputFile()
				}
			)
		}
	}
	
	private var inputSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Input Directory:")
			HStack {
				TextField("Select input directory", text: $viewModel.inputDirectory)
					.textFieldStyle(RoundedBorderTextFieldStyle())
				Button("Browse") {
					viewModel.selectInputDirectory()
				}
				.buttonStyle(BorderedButtonStyle())
			}
		}
	}
	
	private var outputSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Output File:")
			HStack {
				TextField("Select output file location", text: $viewModel.outputFilePath)
					.textFieldStyle(RoundedBorderTextFieldStyle())
				Button("Browse") {
					viewModel.selectOutputFile()
				}
				.buttonStyle(BorderedButtonStyle())
			}
		}
	}
	
	private var optionsSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Toggle("Use Default Ignores", isOn: $viewModel.useDefaultIgnores)
			Toggle("Remove Whitespace", isOn: $viewModel.removeWhitespace)
			Toggle("Show Output Files", isOn: $viewModel.showOutputFiles)
		}
	}
	
	private var ignoreFilesSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Additional files to ignore:")
			HStack {
				TextField("Enter file or pattern to ignore", text: $viewModel.newIgnorePattern)
					.textFieldStyle(RoundedBorderTextFieldStyle())
				Button("Add") {
					viewModel.addIgnorePattern()
				}
				.buttonStyle(BorderedButtonStyle())
			}
			List {
				ForEach(viewModel.customIgnorePatterns.indices, id: \.self) { index in
					HStack {
						Text(viewModel.customIgnorePatterns[index])
						Spacer()
						Button(action: {
							viewModel.removeIgnorePatterns(at: IndexSet(integer: index))
						}) {
							Image(systemName: "trash")
								.foregroundColor(.red)
						}
					}
				}
			}
			.frame(height: 100)
			.border(Color.gray, width: 1)
		}
	}
	
	private var executeButton: some View {
		Button(action: {
			viewModel.aggregateCodebase()
		}) {
			HStack {
				Image(systemName: "arrow.right.circle")
				Text("Distil Code")
			}
			.frame(minWidth: 200)
			.padding()
			.background(Color.blue)
			.foregroundColor(.white)
			.cornerRadius(8)
			.font(.system(size: 16, weight: .semibold))
			.shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
		}
		.buttonStyle(PlainButtonStyle())
		.disabled(viewModel.isProcessing)
		.opacity(viewModel.isProcessing ? 0.6 : 1)
	}
	
	private var logOutputSection: some View {
		VStack(alignment: .leading) {
			Text("Log Output:")
				.font(.headline)
			TextEditor(text: $viewModel.logOutput)
				.font(.system(.body, design: .monospaced))
				.border(Color.gray, width: 1)
		}
	}
}
