//
//  FaceDetection.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/13/22.
//

import Foundation
import Vision
import SwiftUI
import Alamofire
import SwiftyJSON

extension UIImage {
    /// Detects faces using MLKit Vision
    /// 1. Passes image object through MLKit's face detection algorithm
    /// 2. Returns array of observations (including but not limited to bounding boxes, locations of facial structures, etc.)  to the completion handler
    func detectFaces(completion: @escaping ([VNFaceObservation]?) -> Void) {
        let image:UIImage = self.resizeImageTo(size: self.size) // Creates copy of image
        guard let cgImage = image.cgImage else { return } // Unwraps cgImage version of image
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else { return } // Finds and unwraps orientation of image
        
        let request = VNDetectFaceRectanglesRequest() // Creates facial detection request from MLKit
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation) // Creates handler to pass in request
        
        DispatchQueue.global().async {
            try? handler.perform([request]) // Begins processing request asynchronously
            guard let observations = request.results else { return } // Unwraps observations produced from request
            
            return completion(observations) // Returns completion handler
        }
    }
    
    /// Processes API Call by sending image to global AI API link
    /// - parameter image: Image to be sent to AI API link.
    /// - parameter completion: completion handler to be executed using AI output once API call finishes.
    ///1. Is called on entire image to determine age range
    ///2. Is called on all subimages created by slidingWindow() function
    func processAPICall(completion: @escaping (_ prediction:String, _ confidenceScore:Double) -> Void) {
        let image:UIImage = self.resizeImageTo(size: self.size)
        let apiCall = DispatchGroup()
        
        var prediction = ""
        var confidenceScore = 0.0
        // Pre processing before image is sent to AI
        let imageCompressed = image.jpegData(compressionQuality: 0.1)!
        let imageB64 = Data(imageCompressed).base64EncodedData()
        
        // Enters Dispatch Group before starting API Call
        apiCall.enter()
        
        AF.upload(imageB64, to: AIURL).responseDecodable(of: JSON.self) { response in
            switch response.result {
            case .success(let resultJSON):
                prediction = resultJSON["predicted_label"].string ?? ""
                
                // Calculates confidence score of prediction
                let confidence = resultJSON["score"]
                let convertToIndex = ["Kid": 0, "Young Adult": 1, "Adult": 2, "Elderly": 3] // Helper Dictionary to convert Labels to Indexes
                guard let confidenceIndex = convertToIndex[prediction] else { return } // Unwraps Index
                
                
                // TODO: FIX AI AND LABELS
                let convertToLabel = ["Kid": "6-20", "Young Adult": "21-35", "Adult": "36-59", "Elderly": "60+"]
                prediction = convertToLabel[prediction] ?? ""
                
                
                confidenceScore = confidence[confidenceIndex].rawValue as? Double ?? 0.0 // Sets confidenceScore to highest confidence among the categories outputted by the AI
            case .failure:
                print("Failure")
            } // END SWITCH-CASE STATEMENT
            
            // Leaves Dispatch Group after finishing API call
            apiCall.leave()
        } // END UPLOAD
        // Will Not be executed until apiCall dispatch group is empty
        apiCall.notify(queue: .main, execute: {
            // Calls Completion Handler after API Call finishes
            completion(prediction, confidenceScore)
        })
    }

}


    



