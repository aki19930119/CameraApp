//
//  FaceDetecter.swift
//  CameraApp
//
//  Created by 柿沼儀揚 on 2020/04/25.
//  Copyright © 2020 柿沼儀揚. All rights reserved.
//

// 顔検出をするクラス
import UIKit
import AVFoundation

final class FaceDetecter: NSObject {
    private let captureSession = AVCaptureSession()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private var view: UIView
    private var completion: (_ rect: CGRect, _ image: UIImage) -> Void

    required init(view: UIView, completion: @escaping (_ rect: CGRect, _ image: UIImage) -> Void) {
        self.view = view
        self.completion = completion
        super.init()
        self.initialize()
    }
    
    ///初期化する
    private func initialize() {
        addCaptureSessionInput()
        registerDelegate()
        setVideoDataOutput()
        addCaptureSessionOutput()
        addVideoPreviewLayer()
        setCameraOrientation()
        startRunning()
    }
    
    ///キャプチャセッション入力の追加
    private func addCaptureSessionInput() {
        do {
            guard let frontVideoCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
            let frontVideoCameraInput = try AVCaptureDeviceInput(device: frontVideoCamera) as AVCaptureDeviceInput
            captureSession.addInput(frontVideoCameraInput)
        } catch let error {
            print(error)
        }
    }
    ///ビデオデータ出力の設定
    private func setVideoDataOutput() {
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        guard let pixelFormatTypeKey = kCVPixelBufferPixelFormatTypeKey as AnyHashable as? String else { return }
        let pixelFormatTypeValue = Int(kCVPixelFormatType_32BGRA)

        videoDataOutput.videoSettings = [pixelFormatTypeKey : pixelFormatTypeValue]
    }
    ///カメラの方向を設定
    private func setCameraOrientation() {
        for connection in videoDataOutput.connections where connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
    }
    
    ///代理を登録
    private func registerDelegate() {
        let queue = DispatchQueue(label: "queue", attributes: .concurrent)
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    ///キャプチャセッションの出力を追加
    private func addCaptureSessionOutput() {
        captureSession.addOutput(videoDataOutput)
    }
    
    ///ビデオプレビューレイヤーの追加
    private func addVideoPreviewLayer() {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = view.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill

        view.layer.addSublayer(videoPreviewLayer)
    }
    ///実行を開始
    func startRunning() {
        captureSession.startRunning()
    }
    ///実行を停止
    func stopRunning() {
        captureSession.stopRunning()
    }

    ///イメージに変換
    private func convertToImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)

        guard let imageRef = context?.makeImage() else { return nil }

        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage = UIImage(cgImage: imageRef)

        return resultImage
    }
}

extension FaceDetecter: AVCaptureVideoDataOutputSampleBufferDelegate {
    ///キャプチャ出力
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.sync(execute: {

            guard let image = convertToImage(from: sampleBuffer), let ciimage = CIImage(image: image) else { return }
            guard let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return }
            guard let feature = detector.features(in: ciimage).first else { return }

            sendFaceRect(feature: feature, image: image)

        })
    }

    ///面分割を送信
    private func sendFaceRect(feature: CIFeature, image: UIImage) {
        var faceRect = feature.bounds

        let widthPer = view.bounds.width / image.size.width
        let heightPer = view.bounds.height / image.size.height

        // 原点を揃える
        faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height

        // 倍率変換
        faceRect.origin.x *= widthPer
        faceRect.origin.y *= heightPer
        faceRect.size.width *= widthPer
        faceRect.size.height *= heightPer

        completion(faceRect, image)
    }
}
