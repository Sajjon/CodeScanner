//
//  ContentView.swift
//  Shared
//
//  Created by Alexander Cyon on 2022-03-15.
//

import SwiftUI
import CodeScanner

struct ContentView: View {
	@State var isScanning = true
	@State var scannedContent = ""
	var body: some View {
		VStack {
			if isScanning {
				Button(action: {
					isScanning = false
				}, label: {
					Text("Stop scanning").font(.title)
				}).buttonStyle(.borderedProminent).padding()
				
				CodeScannerView(
					codeTypes: [.qr],
					preferPerformanceOverAccuracy: true,
					showViewfinder: true
				) { result in
					switch result {
					case .failure(let error):
						self.scannedContent = "ERROR: \(error.localizedDescription)"
					case .success(let content):
						self.scannedContent = content.string
					}
				}
				
			} else {
				Button(action: {
					isScanning = true
				}, label: {
					Text("Start scanning").font(.title)
				}).buttonStyle(.borderedProminent)
					.padding()
			}
			
			Spacer()
			
			Text("Scanned content:").font(.title)
			ScrollView {
				Text("\(scannedContent)").font(.body)
			}
		}.padding()
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
