//// ColorUtils.swift

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Extract two dominant colors for gradients.
func dominantColors(from image: UIImage) -> [Color] {
    guard let cg = image.cgImage else { return [.gray, .black] }
    let ciImage = CIImage(cgImage: cg)
    let extent = ciImage.extent
    let params: [String: Any] = [
        kCIInputImageKey: ciImage,
        kCIInputExtentKey: CIVector(x: 0, y: 0, z: extent.width, w: extent.height)
    ]
    guard let filter = CIFilter(name: "CIAreaAverage", parameters: params),
          let output = filter.outputImage else {
        return [.gray, .black]
    }
    var bitmap = [UInt8](repeating: 0, count: 4)
    let ctx = CIContext()
    ctx.render(output,
               toBitmap: &bitmap,
               rowBytes: 4,
               bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
               format: .RGBA8,
               colorSpace: CGColorSpaceCreateDeviceRGB())
    let ui = UIColor(
        red: CGFloat(bitmap[0]) / 255,
        green: CGFloat(bitmap[1]) / 255,
        blue: CGFloat(bitmap[2]) / 255,
        alpha: 1
    )
    return [Color(ui), Color(ui).opacity(0.6)]
}
//  ColorUtils.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

