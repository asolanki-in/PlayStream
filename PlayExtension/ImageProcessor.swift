//
//  ImageOptimizer.swift
//  PlayScreen
//
//  Created by Anil Solanki on 22/12/24.
//


import CoreImage
import CoreVideo
import Metal
import UIKit
import UniformTypeIdentifiers

class ImageProcessor {
    
    let screenSize = UIScreen.main.bounds.size
    
    // Create a reusable CIContext with a Metal device for GPU acceleration
    private lazy var ciContext: CIContext = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal device could not be created. Defaulting to software renderer.")
        }
        let options = [CIContextOption.workingColorSpace: NSNull(), CIContextOption.useSoftwareRenderer: NSNumber(value: false)]
        return CIContext(mtlDevice: device, options: options)
    }()
    
    // Function to downscale the image buffer
    func downscaleImageBuffer(_ imageBuffer: CVImageBuffer) -> Data? {
        let coreImage = CIImage(cvImageBuffer: imageBuffer)

        // Calculate the scaling ratio to maintain the aspect ratio
        let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        let aspectWidth = (screenSize.width/1.2) / imageWidth
        let aspectHeight = (screenSize.height/1.2) / imageHeight
        let aspectRatio = min(aspectWidth, aspectHeight) // Maintain aspect ratio without distorting the image

        let scaleTransform = CGAffineTransform(scaleX: aspectRatio, y: aspectRatio)
        let scaledImage = coreImage.transformed(by: scaleTransform)

        // Perform the rendering of the scaled image to a CGImage
        guard let outputImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) else {
            print("Failed to create scaled CGImage")
            return nil
        }

        // Convert the CGImage to JPEG format
        return convertCGImageToJPEG(outputImage)
    }

    // Function to convert a CGImage to JPEG data
    private func convertCGImageToJPEG(_ image: CGImage) -> Data? {
        let jpegData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(jpegData, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        // Adjust compression quality here if needed
        let jpegQuality: CGFloat = 0.80;
        let options = [kCGImageDestinationLossyCompressionQuality: jpegQuality]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return jpegData as Data
    }
}
