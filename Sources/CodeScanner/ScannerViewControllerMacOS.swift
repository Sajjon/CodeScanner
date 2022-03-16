//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-03-15.
//

#if os(macOS)
import AVFoundation
import CoreImage
import CoreVideo
import AppKit

extension CodeScannerView {
	public class ScannerViewControllerMacOS: NSViewController {
		var delegate: ScannerCoordinatorMacOS?
		
		var captureSession: AVCaptureSession?
		var previewLayer: AVCaptureVideoPreviewLayer?
		let fallbackVideoCaptureDevice = AVCaptureDevice.default(for: .video)
		
		var showViewfinder: Bool = true
		
		private lazy var viewFinder: NSImageView? = {
			guard let image = Bundle.module.image(forResource: "viewfinder") else {
				return nil
			}

			let imageView = NSImageView(image: image)
			imageView.translatesAutoresizingMaskIntoConstraints = false
			imageView.imageScaling = .scaleProportionallyUpOrDown
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
			view.layer?.backgroundColor = NSColor.black.cgColor
		}
		
		public override func viewWillLayout() {
			super.viewWillLayout()
			previewLayer?.frame = view.layer!.bounds
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

			if (captureSession!.canAddInput(videoInput)) {
				captureSession!.addInput(videoInput)
			} else {
				delegate?.didFail(reason: .badInput)
				return
			}
			
			
			let videoDataOutput = AVCaptureVideoDataOutput()
			if captureSession!.canAddOutput(videoDataOutput) {
				videoDataOutput.alwaysDiscardsLateVideoFrames = true
				videoDataOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue.main)
				captureSession!.addOutput(videoDataOutput)
			} else {
				assertionFailure("Failed to add delegate.")
				delegate?.didFail(reason: .badOutput)
				return
			}
		}
	
		public override func viewWillAppear() {
			super.viewWillAppear()
			setupSubviews()
		}
		
		public override func viewDidDisappear() {
			super.viewDidDisappear()
			
			if captureSession!.isRunning == true {
				DispatchQueue.global(qos: .userInitiated).async {
					self.captureSession!.stopRunning()
				}
			}
		}
		
		func setupSubviews() {
			if previewLayer == nil {
				previewLayer?.removeFromSuperlayer()
				previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
			}
			
			previewLayer!.videoGravity = .resizeAspectFill
			view.layer!.addSublayer(previewLayer!)
			addviewfinder()

			delegate?.reset()

			if captureSession?.isRunning == false {
				DispatchQueue.global(qos: .userInitiated).async {
					self.captureSession?.startRunning()
				}
			}
		}
		
		private func addviewfinder() {
			guard showViewfinder, let imageView = viewFinder else { return }

			view.addSubview(imageView)

			NSLayoutConstraint.activate([
				imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
				imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
				
				imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
				imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8),
			])
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
