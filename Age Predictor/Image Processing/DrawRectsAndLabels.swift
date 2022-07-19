//
//  DrawRectsAndLabels.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/15/22.
//

import Foundation
import UIKit

extension UIImage {
    
    /// Function used to draw boundingBox rectangles and age labels (if available)
    /// - parameter boundingBoxArray: array containing boundingBox rectangles and prediction labels (empty string label means only bounding box is displayed)
    /// - parameter mode: int variable distinguishing between VideoMode and PhotoMode (0 Video, 1: Photo)
    func drawRectsAndLabelsOnImage(boundingBoxArray:[(CGRect, String)], mode:UInt8) -> UIImage {
        var image:UIImage = self.resizeImageTo(size: self.size) // Creates copy of image
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size)) // Draws original image on new image
        
        for (boundingBox, prediction) in boundingBoxArray {
            // Sets box/label color
            let color:UIColor = .systemPink
            color.set()
            
            // Finds coordinates for Bounding Box on image
            let x1 = boundingBox.minX * image.size.width
            let width = boundingBox.width * image.size.width
            let y1 = (1-boundingBox.maxY) * image.size.height
            let height = boundingBox.height * image.size.height
            
            // Draws bounding box on image
            let rectangle = CGRect(x: x1, y: y1, width: width, height: height) // Creates Rectangle Object at the correct x and y coordinates
            let rect:UIBezierPath = UIBezierPath(rect: rectangle)
            rect.lineWidth = image.size.width / 175
            rect.stroke()
            
            // Information to draw graphic image above head
            if mode == 0 {
                let graphicPoint:CGPoint = CGPoint(
                    x: boundingBox.minX * image.size.width,
                    y: (1-boundingBox.maxY-boundingBox.height/2) * 0.9 * image.size.height)
                // Changes label based on if there is an age prediction inputted
               prediction == "" ? UIImage(named: "WhatAgeAreYouGraphic")?.draw(in: CGRect(origin: graphicPoint, size: CGSize(width: width, height: width)))
                : UIImage(named: "WhatAgeAreYouGraphicNoFill")?.draw(in: CGRect(origin: graphicPoint, size: CGSize(width: width, height: width)))
            }
            
            // Draws text on top of boundingBox
            let point:CGPoint = CGPoint(
                x: (boundingBox.midX + boundingBox.minX) / 1.98 * image.size.width, // Average of minX and midX * image width
                y: (1-boundingBox.maxY-boundingBox.height/2) * 0.9 * image.size.height + width / 3)
            let textFontAttributes = [
                NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: boundingBox.width * image.size.width * 0.2 )!,
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.backgroundColor: UIColor.systemPink, // Draws text with pink background if in Photo Mode else clear background
                ] as [NSAttributedString.Key : Any]
            let textLoc = CGRect(origin: point, size: image.size)
            prediction.draw(in: textLoc, withAttributes: textFontAttributes) // Draws text on image in correct location
            
            image = UIGraphicsGetImageFromCurrentImageContext() ?? image // Unwraps edited image if possible
        }
        UIGraphicsEndImageContext()
        return image
    }
}
