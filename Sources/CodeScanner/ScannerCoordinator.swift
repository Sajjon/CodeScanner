//
//  CodeScanner.swift
//  https://github.com/twostraws/CodeScanner
//
//  Created by Paul Hudson on 14/12/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import AVFoundation
import SwiftUI

#if os(iOS)
extension CodeScannerView {
	public class ScannerCoordinatorIos: NSObject, AVCaptureMetadataOutputObjectsDelegate {
		var parent: CodeScannerView
		var codesFound = Set<String>()
		var didFinishScanning = false
		var lastTime = Date(timeIntervalSince1970: 0)
		
		init(parent: CodeScannerView) {
			self.parent = parent
		}
		
		public func reset() {
			codesFound.removeAll()
			didFinishScanning = false
			lastTime = Date(timeIntervalSince1970: 0)
		}
		
		public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
			if let metadataObject = metadataObjects.first {
				guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
				guard let stringValue = readableObject.stringValue else { return }
				guard didFinishScanning == false else { return }
				let result = ScanResult(string: stringValue, type: readableObject.type)
				
				switch parent.scanMode {
				case .once:
					found(result)
					// make sure we only trigger scan once per use
					didFinishScanning = true
					
				case .oncePerCode:
					if !codesFound.contains(stringValue) {
						codesFound.insert(stringValue)
						found(result)
					}
					
				case .continuous:
					if isPastScanInterval() {
						found(result)
					}
				}
			}
		}
		
		func isPastScanInterval() -> Bool {
			Date().timeIntervalSince(lastTime) >= parent.scanInterval
		}
		
		func found(_ result: ScanResult) {
			lastTime = Date()
			
			if parent.shouldVibrateOniOSAndFlashOnMacOSOnSuccess {
				AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
			}
			
			parent.completion(.success(result))
		}
		
		func didFail(reason: ScanError) {
			parent.completion(.failure(reason))
		}
	}
}

#elseif os(macOS)
extension CodeScannerView {
	public class ScannerCoordinatorMacOS: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate  { //, AVCaptureMetadataOutputObjectsDelegate {
		var parent: CodeScannerView
		var codesFound = Set<String>()
		var didFinishScanning = false
		var lastTime = Date(timeIntervalSince1970: 0)
		
		lazy var qrDetector: CIDetector = {
			var options: [String: Any] = [:]
			
			if parent.preferPerformanceOverAccuracy {
				options[CIDetectorAccuracyLow] = true
			}
			
			guard let detector = CIDetector(
				ofType: CIDetectorTypeQRCode,
				context: nil,
				options: options.isEmpty ? nil : options
			) else {
				fatalError()
			}
			return detector
		}()
		
		init(parent: CodeScannerView) {
			self.parent = parent
		}
		
		public func reset() {
			codesFound.removeAll()
			didFinishScanning = false
			lastTime = Date(timeIntervalSince1970: 0)
		}
		
		// MARK: Video
		public func captureOutput(
			_ output: AVCaptureOutput,
			didOutput sampleBuffer: CMSampleBuffer,
			from connection: AVCaptureConnection
		) {

			guard didFinishScanning == false else { return }
			
			guard
				let imageBuf = CMSampleBufferGetImageBuffer(sampleBuffer)
			else {
				return
			}
			let frame: CIImage = CIImage(cvImageBuffer: imageBuf)
			let features: [CIFeature] = qrDetector.features(in: frame, options: nil)
			let qrCodeFeatures = features.compactMap { $0 as? CIQRCodeFeature }
			
			guard let qrCodeString = qrCodeFeatures.first?.messageString else {
				return
			}
			
			let result = ScanResult(string: qrCodeString, type: .qr)
			
			switch parent.scanMode {
			case .once:
				found(result)
				// make sure we only trigger scan once per use
				didFinishScanning = true
				
			case .oncePerCode:
				if !codesFound.contains(qrCodeString) {
					codesFound.insert(qrCodeString)
					found(result)
				}
				
			case .continuous:
				if isPastScanInterval() {
					found(result)
				}
			}
		}
		
		func isPastScanInterval() -> Bool {
			Date().timeIntervalSince(lastTime) >= parent.scanInterval
		}
		
		func found(_ result: ScanResult) {
			lastTime = Date()
			
			if parent.shouldVibrateOniOSAndFlashOnMacOSOnSuccess {
				AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_FlashScreen))
			}
			
			parent.completion(.success(result))
		}
		
		func didFail(reason: ScanError) {
			parent.completion(.failure(reason))
		}
	}
}


#endif // os(iOS)
