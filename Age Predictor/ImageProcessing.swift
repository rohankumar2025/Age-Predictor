//
//  ImageProcessing.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 6/27/22.
//

import Foundation
import SwiftUI
import Alamofire
import SwiftyJSON
import UIKit

extension UIImage {
    
    // Extension to UIImage class to resize UIImage for ImagePyramid (taken directly from StackOverflow)
    func resizeImageTo(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

func imagePyramid(image:UIImage, scale:CGFloat = 1.5, minX:CGFloat = 100, minY:CGFloat = 100) -> Array<UIImage> {
    var arrayOut:Array<UIImage> = [image] // adds original image to pyramid
    var newImage:UIImage = image // creates copy of original image
    
    while true {
        // Computes resized image based on original image and scale parameter
        let targSize = CGSize(width: newImage.size.width / scale, height: newImage.size.height / scale)
        
        // Resizes newImage and assigns it back to newImage
        if let newImg = newImage.resizeImageTo(size: targSize) {
            newImage = newImg
        } else { // Ends Loop if newImage does not unwrap correctly
            break
        }
        
        // Checks if resized image is smaller than minX and minY parameters
        if newImage.size.width < minX || newImage.size.height < minY {
            break
        }
        
        // Appends resized image to output array if all conditions are met
        arrayOut.append(newImage)
    }
    
    return arrayOut
}

func slidingWindow(image:UIImage, step:Int, windowSize:(Int, Int)) -> [(Int, Int, UIImage)] {
    var arrayOut:Array< (Int, Int, UIImage) > = [] // creates array of images
    
    // slides through image's height by increments of step parameter
    for y in stride(from: 0, through: Int(image.size.height) - windowSize.1, by: step) {
        // slides through image's width by increments of step parameter
        for x in stride(from: 0, through: Int(image.size.width) - windowSize.0, by: step) {
            // creates rectangle at x and y with the size of windowSize
            let rec = CGRect(x: x, y: y, width: windowSize.0, height: windowSize.1)
            let subImage = UIImage(cgImage: image.cgImage!.cropping(to: rec)!)
            arrayOut.append( (x, y, subImage) ) // adds calculated subImage to output array
        }
    }
    return arrayOut
}

