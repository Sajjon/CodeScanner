//
//  CodeScanner.swift
//  https://github.com/twostraws/CodeScanner
//
//  Created by Paul Hudson on 14/12/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import AVFoundation
import SwiftUI

/// An enum describing the ways CodeScannerView can hit scanning problems.
public enum ScanError: Error {
    /// The camera could not be accessed.
    case badInput

    /// The camera was not capable of scanning the requested codes.
    case badOutput

    /// Initialization failed.
    case initError(_ error: Error)
}

/// The result from a successful scan: the string that was scanned, and also the type of data that was found.
/// The type is useful for times when you've asked to scan several different code types at the same time, because
/// it will report the exact code type that was found.
public struct ScanResult {
    /// The contents of the code.
    public let string: String

    /// The type of code that was matched.
    public let type: AVMetadataObject.ObjectType
}

/// The operating mode for CodeScannerView.
public enum ScanMode {
    /// Scan exactly one code, then stop.
    case once

    /// Scan each code no more than once.
    case oncePerCode

    /// Keep scanning all codes until dismissed.
    case continuous
}

public protocol CodeScannerViewProtocol {
	var config: CodeScannerConfig { get }
	init(
		codeTypes: [AVMetadataObject.ObjectType],
		scanMode: ScanMode,
		scanInterval: Double,
		preferPerformanceOverAccuracy: Bool,
		showViewfinder: Bool,
		simulatedData: String,
		shouldVibrateOniOSAndFlashOnMacOSOnSuccess: Bool,
		isTorchOn: Bool,
		isGalleryPresented: Binding<Bool>,
		videoCaptureDevice: AVCaptureDevice?,
		completion: @escaping (Result<ScanResult, ScanError>) -> Void
	)
}

internal extension CodeScannerViewProtocol {
	var codeTypes: [AVMetadataObject.ObjectType] { config.codeTypes }
	var scanMode: ScanMode { config.scanMode }
	var scanInterval: Double { config.scanInterval }
	var preferPerformanceOverAccuracy: Bool { config.preferPerformanceOverAccuracy }
	var showViewfinder: Bool { config.showViewfinder }
	var simulatedData: String { config.simulatedData }
	
	
	var shouldVibrateOniOSAndFlashOnMacOSOnSuccess: Bool { config.shouldVibrateOniOSAndFlashOnMacOSOnSuccess }
	
	var isTorchOn: Bool { config.isTorchOn }
	var isGalleryPresented: Binding<Bool> { config.isGalleryPresented }
	var videoCaptureDevice: AVCaptureDevice? { config.videoCaptureDevice }
	var completion: (Result<ScanResult, ScanError>) -> Void { config.completion }
}

public extension CodeScannerViewProtocol {
	init(
		_ codeTypes: [AVMetadataObject.ObjectType],
		scanMode: ScanMode = .once,
		scanInterval: Double = 2.0,
		preferPerformanceOverAccuracy: Bool = false,
		showViewfinder: Bool = false,
		simulatedData: String = "",
		shouldVibrateOniOSAndFlashOnMacOSOnSuccess: Bool = true,
		isTorchOn: Bool = false,
		isGalleryPresented: Binding<Bool> = .constant(false),
		videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video),
		completion: @escaping (Result<ScanResult, ScanError>) -> Void
	) {
		self.init(
			codeTypes: codeTypes,
			scanMode: scanMode,
			scanInterval: scanInterval,
			preferPerformanceOverAccuracy: preferPerformanceOverAccuracy,
			showViewfinder: showViewfinder,
			simulatedData: simulatedData,
			shouldVibrateOniOSAndFlashOnMacOSOnSuccess: shouldVibrateOniOSAndFlashOnMacOSOnSuccess,
			isTorchOn: isTorchOn,
			isGalleryPresented: isGalleryPresented,
			videoCaptureDevice: videoCaptureDevice,
			completion: completion
		)
	}
}

public struct CodeScannerConfig {
	public let codeTypes: [AVMetadataObject.ObjectType]
	public let scanMode: ScanMode
	public let scanInterval: Double
	public var preferPerformanceOverAccuracy: Bool
	public let showViewfinder: Bool
	public var simulatedData: String
	public var shouldVibrateOniOSAndFlashOnMacOSOnSuccess: Bool
	public var isTorchOn: Bool
	public var isGalleryPresented: Binding<Bool>
	public var videoCaptureDevice: AVCaptureDevice?
	public var completion: (Result<ScanResult, ScanError>) -> Void

	public init(
		codeTypes: [AVMetadataObject.ObjectType],
		scanMode: ScanMode = .once,
		scanInterval: Double = 2.0,
		preferPerformanceOverAccuracy: Bool = false,
		showViewfinder: Bool = false,
		simulatedData: String = "",
		shouldVibrateOniOSAndFlashOnMacOSOnSuccess: Bool = true,
		isTorchOn: Bool = false,
		isGalleryPresented: Binding<Bool> = .constant(false),
		videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video),
		completion: @escaping (Result<ScanResult, ScanError>) -> Void
	) {
		self.codeTypes = codeTypes
		self.scanMode = scanMode
		self.showViewfinder = showViewfinder
		self.scanInterval = scanInterval
		self.preferPerformanceOverAccuracy = preferPerformanceOverAccuracy
		self.simulatedData = simulatedData
		self.shouldVibrateOniOSAndFlashOnMacOSOnSuccess = shouldVibrateOniOSAndFlashOnMacOSOnSuccess
		self.isTorchOn = isTorchOn
		self.isGalleryPresented = isGalleryPresented
		self.videoCaptureDevice = videoCaptureDevice
		self.completion = completion
	}

}

#if os(iOS)

/// A SwiftUI view that is able to scan barcodes, QR codes, and more, and send back what was found.
/// To use, set `codeTypes` to be an array of things to scan for, e.g. `[.qr]`, and set `completion` to
/// a closure that will be called when scanning has finished. This will be sent the string that was detected or a `ScanError`.
/// For testing inside the simulator, set the `simulatedData` property to some test data you want to send back.
public struct CodeScannerView: CodeScannerViewProtocol, UIViewControllerRepresentable {

	public let config: CodeScannerConfig
	
	public init(config: CodeScannerConfig) {
		self.config = config
	}
	
	public init(
		codeTypes: [AVMetadataObject.ObjectType],
		scanMode: ScanMode = .once,
		scanInterval: Double = 2.0,
		preferPerformanceOverAccuracy: Bool = false,
		showViewfinder: Bool = false,
		simulatedData: String = "",
		shouldVibrateOniOSAndFlashOnMacOSOnSuccess: Bool = true,
		isTorchOn: Bool = false,
		isGalleryPresented: Binding<Bool> = .constant(false),
		videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video),
		completion: @escaping (Result<ScanResult, ScanError>) -> Void
	) {
		self.init(
			config: .init(
				codeTypes: codeTypes,
				scanMode: scanMode,
				scanInterval: scanInterval,
				preferPerformanceOverAccuracy: preferPerformanceOverAccuracy,
				showViewfinder: showViewfinder,
				simulatedData: simulatedData,
				shouldVibrateOniOSAndFlashOnMacOSOnSuccess: shouldVibrateOniOSAndFlashOnMacOSOnSuccess,
				isTorchOn: isTorchOn,
				isGalleryPresented: isGalleryPresented,
				videoCaptureDevice: videoCaptureDevice,
				completion: completion
			)
		)
	}
	
	public typealias Coordinator = ScannerCoordinatorIos
	public typealias UIViewControllerType = ScannerViewControllerIos
  
    public func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
    }

    public func makeUIViewController(context: Context) -> UIViewControllerType {
		let viewController = UIViewControllerType(
			showViewfinder: config.showViewfinder
		)
		
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.updateViewController(
			isTorchOn: config.isTorchOn,
			isGalleryPresented: config.isGalleryPresented.wrappedValue
        )
    }
    
}

struct CodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        CodeScannerView(codeTypes: [.qr]) { result in
            // do nothing
        }
    }
}

#elseif os(macOS)

public struct CodeScannerView: CodeScannerViewProtocol, NSViewControllerRepresentable {

	public typealias Coordinator = ScannerCoordinatorMacOS
	public typealias NSViewControllerType = ScannerViewControllerMacOS
	
	public let config: CodeScannerConfig
	
	public init(config: CodeScannerConfig) {
		self.config = config
	}
	
	public init(
		codeTypes: [AVMetadataObject.ObjectType],
		scanMode: ScanMode = .oncePerCode,
		scanInterval: Double = 2.0,
		preferPerformanceOverAccuracy: Bool = false,
		showViewfinder: Bool = false,
		simulatedData: String = "",
		shouldVibrateOniOSAndFlashOnMacOSOnSuccess: Bool = true,
		isTorchOn: Bool = false,
		isGalleryPresented: Binding<Bool> = .constant(false),
		videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video),
		completion: @escaping (Result<ScanResult, ScanError>) -> Void
	) {
		self.init(
			config: .init(
				codeTypes: codeTypes,
				scanMode: scanMode,
				scanInterval: scanInterval,
				preferPerformanceOverAccuracy: preferPerformanceOverAccuracy,
				showViewfinder: showViewfinder,
				simulatedData: simulatedData,
				shouldVibrateOniOSAndFlashOnMacOSOnSuccess: shouldVibrateOniOSAndFlashOnMacOSOnSuccess,
				isTorchOn: isTorchOn,
				isGalleryPresented: isGalleryPresented,
				videoCaptureDevice: videoCaptureDevice,
				completion: completion
			)
		)
	}
	
	public func makeNSViewController(context: Context) -> NSViewControllerType {
		let viewController = NSViewControllerType()
		viewController.showViewfinder = config.showViewfinder
		viewController.delegate = context.coordinator
		return viewController
	}

	public func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
		nsViewController.updateViewController(
			isTorchOn: config.isTorchOn,
			isGalleryPresented: config.isGalleryPresented.wrappedValue
		)
	}
	public func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}
}

#endif
