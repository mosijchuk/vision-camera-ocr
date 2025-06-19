import Foundation
import VisionCamera
import MLKitVision
import MLKitTextRecognition

@objc(OCRFrameProcessorPlugin)
public class OCRFrameProcessorPlugin: FrameProcessorPlugin {

    private static var textRecognizer = TextRecognizer.textRecognizer(options: TextRecognizerOptions())

    public override init(proxy: VisionCameraProxyHolder, options: [AnyHashable : Any]! = [:]) {
        super.init(proxy: proxy, options: options)
    }

    public override func callback(_ frame: Frame, withArguments arguments: [AnyHashable : Any]?) -> Any {

        guard let buffer = CMSampleBufferGetImageBuffer(frame.buffer) else {
            return ["error": "Failed to get image buffer"]
        }

        let visionImage = VisionImage(buffer: frame.buffer)
        visionImage.orientation = frame.orientation

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
