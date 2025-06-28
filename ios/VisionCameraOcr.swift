import Foundation
import VisionCamera
import MLKitVision
import MLKitTextRecognition
import CoreMotion
import UIKit

@objc(OCRFrameProcessorPlugin)
public class OCRFrameProcessorPlugin: FrameProcessorPlugin {

    private static var textRecognizer = TextRecognizer.textRecognizer(options: TextRecognizerOptions())
    private var orientationManager = OCROrientationManager()
    private let ciContext = CIContext()

    public override init(proxy: VisionCameraProxyHolder, options: [AnyHashable : Any]! = [:]) {
        super.init(proxy: proxy, options: options)
    }

    func getImageOrientation() -> UIImage.Orientation {
        switch orientationManager.orientation {
        case .portrait:
            return .right
        case .landscapeLeft:
            return .up
        case .portraitUpsideDown:
            return .left
        case .landscapeRight:
            return .down
        @unknown default:
            return .up
        }
    }

    public override func callback(_ frame: Frame, withArguments arguments: [AnyHashable : Any]?) -> Any {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(frame.buffer) else {
            return ["error": "Failed to get image buffer"]
        }

        var ciImage = CIImage(cvPixelBuffer: imageBuffer)

        if frame.isMirrored {
            let flipTransform = CGAffineTransform(scaleX: -1, y: 1)
            let translateTransform = CGAffineTransform(translationX: ciImage.extent.width, y: 0)
            ciImage = ciImage.transformed(by: flipTransform.concatenating(translateTransform))
        }

        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return ["error": "Failed to create CGImage"]
        }

        let uiImage = UIImage(cgImage: cgImage)

        let visionImage = VisionImage(image: uiImage)
        visionImage.orientation = getImageOrientation()

        do {
            let result = try Self.textRecognizer.results(in: visionImage)

            return [
                "result": [
                    "text": result.text,
                    "blocks": getBlockArray(result.blocks)
                ]
            ]
        } catch {
            return ["error": error.localizedDescription]
        }
    }

    private func getBlockArray(_ blocks: [TextBlock]) -> [[String: Any]] {
        return blocks.map { block in
            [
                "text": block.text,
                "recognizedLanguages": getRecognizedLanguages(block.recognizedLanguages),
                "cornerPoints": getCornerPoints(block.cornerPoints),
                "frame": getFrame(block.frame),
                "lines": getLineArray(block.lines)
            ]
        }
    }

    private func getLineArray(_ lines: [TextLine]) -> [[String: Any]] {
        return lines.map { line in
            [
                "text": line.text,
                "recognizedLanguages": getRecognizedLanguages(line.recognizedLanguages),
                "cornerPoints": getCornerPoints(line.cornerPoints),
                "frame": getFrame(line.frame),
                "elements": getElementArray(line.elements)
            ]
        }
    }

    private func getElementArray(_ elements: [TextElement]) -> [[String: Any]] {
        return elements.map { element in
            [
                "text": element.text,
                "cornerPoints": getCornerPoints(element.cornerPoints),
                "frame": getFrame(element.frame)
            ]
        }
    }

    private func getRecognizedLanguages(_ languages: [TextRecognizedLanguage]) -> [String] {
        return languages.compactMap { $0.languageCode }
    }

    private func getCornerPoints(_ cornerPoints: [NSValue]) -> [[String: CGFloat]] {
        return cornerPoints.compactMap { value in
            let point = value.cgPointValue
            return ["x": point.x, "y": point.y]
        }
    }

    private func getFrame(_ frameRect: CGRect) -> [String: CGFloat] {
        return [
            "x": frameRect.origin.x,
            "y": frameRect.origin.y,
            "width": frameRect.width,
            "height": frameRect.height,
            "boundingCenterX": frameRect.midX,
            "boundingCenterY": frameRect.midY
        ]
    }
}

enum Orientation: String {
    case portrait = "portrait"
    case landscapeLeft = "landscapeLeft"
    case portraitUpsideDown = "portraitUpsideDown"
    case landscapeRight = "landscapeRight"
}

final class OCROrientationManager {
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()

    var orientation: Orientation {
        didSet {
            if oldValue != orientation {
                print("Device Orientation changed from \(oldValue) -> \(orientation)")
            }
        }
    }

    init() {
        orientation = .portrait
        startDeviceOrientationListener()
    }

    deinit {
        stopDeviceOrientationListener()
    }

    private func startDeviceOrientationListener() {
        stopDeviceOrientationListener()
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates(to: operationQueue) { accelerometerData, error in
                if let error {
                    print("Failed to get Accelerometer data! \(error)")
                }
                if let accelerometerData {
                    self.orientation = accelerometerData.deviceOrientation
                }
            }
        }
    }

    private func stopDeviceOrientationListener() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
    }
}

extension CMAccelerometerData {
    var deviceOrientation: Orientation {
        let acceleration = acceleration
        let xNorm = abs(acceleration.x)
        let yNorm = abs(acceleration.y)
        let zNorm = abs(acceleration.z)

        if zNorm > xNorm && zNorm > yNorm {
            return .portrait
        }

        if xNorm > yNorm {
            if acceleration.x > 0 {
                return .landscapeRight
            } else {
                return .landscapeLeft
            }
        } else {
            if acceleration.y > 0 {
                return .portraitUpsideDown
            } else {
                return .portrait
            }
        }
    }
}
