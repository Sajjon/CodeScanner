//
//  ContentView.swift
//  Shared
//
//  Created by Alexander Cyon on 2022-03-15.
//

import SwiftUI
import CodeScanner

struct ContentView: View {
	@State var scannedContent = ""
    var body: some View {
		VStack {
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
			
			Spacer()
			
			Text("Scanned content:")
			Text("\(scannedContent)")
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
