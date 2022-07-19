//
//  HelperUIImageExtensions.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/18/22.
//

import Foundation
import SwiftUI
import UIKit

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
    
    /// Helper function that crops image into a subimage, corresponding to the rectangle
    /// - parameter boundingBox: CGRect that holds decimal values between 0-1 for minX, minY, width, height
    func croppedTo(boundingBox: CGRect) -> UIImage {
        let image:UIImage = self.resizeImageTo(size: self.size) // Creates copy of image
        // Finds coordinates for Bounding Box on image
        let x1 = boundingBox.minX * image.size.width
        let width = boundingBox.width * image.size.width
        let y1 = (1-boundingBox.maxY) * image.size.height
        let height = boundingBox.height * image.size.height
        // Crops Image using cgImage
        guard let croppedImg = image.cgImage?.cropping(to: CGRect(x: x1, y: y1, width: width, height: height)) else { return image }
        return UIImage(cgImage: croppedImg)
    }
}
