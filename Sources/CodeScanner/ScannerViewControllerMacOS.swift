//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-03-15.
//

import AVFoundation
import CoreImage
import CoreVideo
#if os(macOS)
import AppKit
extension CodeScannerView {
	public class ScannerViewControllerMacOS: NSViewController {
		var delegate: ScannerCoordinatorMacOS?
		
		var captureSession: AVCaptureSession!
		var previewLayer: AVCaptureVideoPreviewLayer!
		let fallbackVideoCaptureDevice = AVCaptureDevice.default(for: .video)
		
		var showViewfinder: Bool = true
		
		private lazy var viewFinder: NSImageView? = {
			guard let image = Bundle.module.image(forResource: "viewfinder") else {
				fatalError("expected image?")
			}

			let imageView = NSImageView(image: image)
			imageView.translatesAutoresizingMaskIntoConstraints = false
			return imageView
		}()
		
		public init() {
		   super.init(nibName: nil, bundle: nil)
		}

		required init?(coder: NSCoder) {
		   fatalError()
		}
		
		public override func loadView() {
			view = NSView()
			view.wantsLayer = true
			view.layer?.backgroundColor = NSColor.blue.cgColor
			
		
		}
		
		public override func viewDidLoad() {
			super.viewDidLoad()
			
			captureSession = AVCaptureSession()
			
			guard let videoCaptureDevice = delegate?.parent.videoCaptureDevice ?? fallbackVideoCaptureDevice else {
				return
			}

			let videoInput: AVCaptureDeviceInput

			do {
				videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
				
			} catch {
				delegate?.didFail(reason: .initError(error))
				return
			}

			if (captureSession.canAddInput(videoInput)) {
				captureSession.addInput(videoInput)
			} else {
				delegate?.didFail(reason: .badInput)
				return
			}
			
			
			let videoDataOutput = AVCaptureVideoDataOutput()
			if captureSession.canAddOutput(videoDataOutput) {
				videoDataOutput.alwaysDiscardsLateVideoFrames = true
				videoDataOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue.main)
				captureSession.addOutput(videoDataOutput)
			} else {
				assertionFailure("Failed to add delegate.")
				delegate?.didFail(reason: .badOutput)
				return
			}
		}
		
		public override func viewDidDisappear() {
			super.viewDidDisappear()
			
			if captureSession?.isRunning == true {
				DispatchQueue.global(qos: .userInitiated).async {
					self.captureSession.stopRunning()
				}
			}
		}
		
		private func addviewfinder() {
			guard showViewfinder, let imageView = viewFinder else { return }

			view.addSubview(imageView)

			NSLayoutConstraint.activate([
				imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
				imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
				imageView.widthAnchor.constraint(equalToConstant: 200),
				imageView.heightAnchor.constraint(equalToConstant: 200),
			])
		}
		
		public override func viewWillAppear() {
			super.viewWillAppear()
			if previewLayer == nil {
				previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
			}

			previewLayer.frame = view.layer!.bounds
			previewLayer.videoGravity = .resizeAspectFill
			view.layer!.addSublayer(previewLayer)
			addviewfinder()

			delegate?.reset()

			if captureSession?.isRunning == false {
				DispatchQueue.global(qos: .userInitiated).async {
					self.captureSession.startRunning()
				}
			}
		}
		
		
		func updateViewController(isTorchOn: Bool, isGalleryPresented: Bool) {
			if
				let backCamera = AVCaptureDevice.default(for: AVMediaType.video),
				backCamera.hasTorch
			{
				try? backCamera.lockForConfiguration()
				backCamera.torchMode = isTorchOn ? .on : .off
				backCamera.unlockForConfiguration()
			}

		}
		
	
	}
	
}

#endif // os(macOS)
