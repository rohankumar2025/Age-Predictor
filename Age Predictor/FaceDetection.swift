//
//  FaceDetection.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/13/22.
//

import Foundation
import Vision
import SwiftUI

extension UIImage {
    
    /// Helper function that resizes image to a certain size, simply returns image if size = self.size
    /// - parameter size: CGSize variable that holds x and y values, which the image will be resized to
    func resizeImageTo(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func detectFaces(completion: @escaping ([VNFaceObservation]?) -> Void) {
        let image:UIImage = self.resizeImageTo(size: self.size) // Creates copy of image
        guard let cgImage = image.cgImage else { return }
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else { return }
        
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
        
        DispatchQueue.global().async {
            try? handler.perform([request])
            
            guard let observations = request.results else { return }
            
            return completion(observations)
        }
    }
    
    
    func drawRectanglesOnImage(boundingBoxes: [CGRect], color:UIColor = .systemRed) -> UIImage {
        var editedInputImage:UIImage = self.resizeImageTo(size: self.size)
        let imageSize = editedInputImage.size
        
        for boundingBox in boundingBoxes {
            // Finds coordinates for Bounding Box on image
            let x1 = boundingBox.minX * imageSize.width
            let width = boundingBox.width * imageSize.width
            let y1 = (1-boundingBox.maxY) * imageSize.height
            let height = boundingBox.height * imageSize.height
            
            print("MaxY: \(boundingBox.maxY), MinY: \(boundingBox.minY)")
            // Begins Drawing
            UIGraphicsBeginImageContext(imageSize)
            editedInputImage.draw(at: CGPoint.zero) // Redraws original image
            let rectangle = CGRect(x: x1, y: y1, width: width, height: height) // Creates Rectangle Object at the correct x and y coordinates
            color.set()
            // Draws Rectangle "Path" on top of UIImage
            let rect:UIBezierPath = UIBezierPath(rect: rectangle)
            rect.lineWidth = imageSize.width / 175
            rect.stroke()
            editedInputImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext() // Ends Drawing
            
        }
        return editedInputImage // Replaces inputImage with inputImage with Rectangles
    }
    
    
}
