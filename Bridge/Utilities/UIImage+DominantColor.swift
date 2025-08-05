//// UIImage+DominantColor.swift

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    /// Returns the average color of the image.
    func dominantColor() -> UIColor? {
        guard let ci = CIImage(image: self) else { return nil }
        let extent = ci.extent
        let params: [String: Any] = [
            kCIInputImageKey: ci,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ]
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: params),
              let out = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let ctx = CIContext()
        ctx.render(out,
                   toBitmap: &bitmap,
                   rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8,
                   colorSpace: CGColorSpaceCreateDeviceRGB())

        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1
        )
    }
}

//  Created by Max stevenson on 8/5/25.
//

