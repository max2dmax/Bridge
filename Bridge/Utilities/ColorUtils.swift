//
// ColorUtils.swift
// Bridge
//
// This file contains color utility functions for extracting dominant colors from images.
// Used to create dynamic gradient backgrounds based on project artwork.
// Supports both "All" mode (all projects) and "Selected" mode (specific projects).
//

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

/// Generate gradient colors based on user preferences and available projects
/// Supports both "All" mode (all projects) and "Selected" mode (specific projects)
func generateGradientColors(projects: [Project], preferences: UserPreferences) -> [Color] {
    let relevantProjects: [Project]
    
    switch preferences.gradientMode {
    case .all:
        relevantProjects = projects
    case .selected:
        // Filter projects by selected IDs
        let selectedIds = Set(preferences.selectedProjectIds)
        relevantProjects = projects.filter { selectedIds.contains($0.id) }
    }
    
    // Get all artworks from relevant projects
    let artworks = relevantProjects.compactMap { $0.artwork }
    
    // If no artworks available, return default gradient
    guard !artworks.isEmpty else {
        return [Color.gray.opacity(0.2), Color.black.opacity(0.3)]
    }
    
    // For multiple artworks, blend the dominant colors
    if artworks.count == 1 {
        return dominantColors(from: artworks[0])
    } else {
        return blendedGradientColors(from: artworks)
    }
}

/// Create blended gradient colors from multiple artworks
private func blendedGradientColors(from artworks: [UIImage]) -> [Color] {
    var allColors: [UIColor] = []
    
    // Extract dominant color from each artwork
    for artwork in artworks {
        if let dominantColor = artwork.dominantColor() {
            allColors.append(dominantColor)
        }
    }
    
    // If no colors extracted, return default
    guard !allColors.isEmpty else {
        return [Color.gray.opacity(0.2), Color.black.opacity(0.3)]
    }
    
    // Blend colors for gradient effect
    if allColors.count == 1 {
        let color = Color(allColors[0])
        return [color, color.opacity(0.6)]
    } else if allColors.count == 2 {
        return [Color(allColors[0]), Color(allColors[1]).opacity(0.8)]
    } else {
        // For 3+ colors, use first and last with some blending
        let firstColor = Color(allColors.first!)
        let lastColor = Color(allColors.last!)
        return [firstColor, lastColor.opacity(0.7)]
    }
}
//  ColorUtils.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

