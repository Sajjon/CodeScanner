//
//  CodeScannerDemoApp.swift
//  Shared
//
//  Created by Alexander Cyon on 2022-03-15.
//

import SwiftUI

@main
struct CodeScannerDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
			#if os(macOS)
				.frame(minWidth: 800, maxWidth: .infinity, minHeight: 800, maxHeight: .infinity)
			#endif // os(macOS)
        }
    }
}
