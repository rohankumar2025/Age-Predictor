//
//  ContentView.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 6/23/22.
//

import SwiftUI
import Alamofire
import SwiftyJSON

let UIPink = Color.init(red: 1, green: 0.2, blue: 0.56)

struct ContentView: View {
    @State var predictedAgeGroup = " "
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage? = UIImage(named: "default")
    @State private var loadingText = " "
        
    var body: some View {
        VStack {
            HeaderView()
                .frame(height:70, alignment:.top)
            Spacer()
            HStack {
                ZStack {
                    Text("Your Calculated Age:")
                        .font(.system(size: 30, design: .rounded))
                        .foregroundColor(.gray)
                        .frame(height: 650, alignment: .top)
                        .multilineTextAlignment(.center)
                    
                    
                    Text(predictedAgeGroup) // PREDICTED AGE
                        .font(.system(size: 40, design: .rounded))
                        .foregroundColor(.gray)
                        .frame(height: 570, alignment: .top)
                        .multilineTextAlignment(.center)
                    
                    Text(loadingText) // Loading Screen
                        .font(.system(size: 20, design: .rounded))
                        .foregroundColor(.gray)
                        .frame(height: 480, alignment: .top)
                        .multilineTextAlignment(.center)
                    
                    if let i = inputImage { // IMAGE
                        Image(uiImage: i).resizable()
                            .cornerRadius(25)
                            .shadow(color: .black, radius: 5)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 325, height: 300, alignment: .top)
                    }
                    
                    Button("How Old Am I?"){ // SUBMIT BUTTON
                        self.showingImagePicker = true
                    }
                    .padding(.all, 14.0)
                    .background(UIPink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(height:600, alignment: .bottom)
                }
                .font(.title)
            }.sheet(isPresented: $showingImagePicker, onDismiss: processImage) {
                ImagePicker(image: self.$inputImage)
            }
        }
    }
    
    func processImage() {
        self.showingImagePicker = false // Removes Camera Roll Image picker from UI
        self.predictedAgeGroup="..." // Temporary Message while AI is loading
        guard let inputImage = inputImage else {return} // Unwraps inputImage

        // Processes API Call on whole image
        processAPICall(image: inputImage, {(prediction, _) in
            // Displays prediction to UI
            self.predictedAgeGroup = convertToAgeGroup(prediction)
        })
        
        self.loadingText = "Detecting Objects..."
        // Calls Object Detection Function
        detectObjsInImage(image: inputImage)
    }
    
    func processAPICall(image: UIImage, _
        completion: @escaping (_ prediction:String, _ confidenceScore:Double) -> Void) {
        let uploadURL="https://askai.aiclub.world/018cb7b9-ad1c-4c60-84a1-267fac249865" // AI URL
        let apiCall = DispatchGroup()
        
        var prediction = ""
        var confidenceScore = 0.0
        // Pre processing before image is sent to AI
        let imageJPG = image.jpegData(compressionQuality: 0.0034)!
        let imageB64 = Data(imageJPG).base64EncodedData()
        
        // Enters Dispatch Group before starting API Call
        apiCall.enter()
        
        AF.upload(imageB64, to: uploadURL).responseJSON { response in
            switch response.result {
            case .success(let responseJsonStr):
                let myJson = JSON(responseJsonStr) // Converts response into JSON Format
                if let pred = myJson["predicted_label"].string {
                    prediction = pred // Parses response to find prediction
                }
                
                // Calculates confidence score of prediction
                let confidence = Array(myJson["score"])
                // Sets confidenceScore to highest confidence among the 4 categories outputted by the AI
                for (_, c2) in confidence {
                    if ((c2.rawValue as! Double) > confidenceScore) { confidenceScore = c2.rawValue as! Double}
                }
            case .failure:
                print("Failure")
            } // END SWITCH-CASE STATEMENT
            
            // Leaves Dispatch Group after finishing API call
            apiCall.leave()
        } // END UPLOAD
            
        
        apiCall.notify(queue: .main, execute: {
            // Calls Completion Handler after API Call finishes
            completion(prediction, confidenceScore)
        })
    }

    func detectObjsInImage(image: UIImage) {
        // initialize constants used for the object detection procedure
        let PYR_SCALE = 1.75 // Scale factor used in imagePyramid() function (Higher Value = faster, less accurate)
        let WIN_STEP = 25 // Size of step that the Sliding Window is taking
        let ROI_SIZE = (175, 175) // Dimensions of Sliding Window (Should be close in size to the object/face)
        let MIN_CONFIDENCE_SCORE = 0.88 // Threshold value for rectangle to be drawn
        let INPUT_SIZE = (image.size.width, image.size.height) // Dimensions of Original Image

        var arrayOut:[((Int, Int, Int, Int), Double)] = [] // Array containing [ ( (X+Y Coordinates for rectangle), Confidence_Score ) ]
        let pyramid = imagePyramid(image: image, scale: PYR_SCALE)
        
        let apiCall = DispatchGroup() // Creates DispatchGroup for apiCall
        
        for img in pyramid {
            // Finds scale factor between current image in pyramid and original
            // Scale factor is used to calculate x and y values of ROI
            let scale = INPUT_SIZE.0 / img.size.width
            
            // Loops through sliding window for every image in image pyramid
            for (i, j, roiOrig) in slidingWindow(image: img, step: WIN_STEP, windowSize: ROI_SIZE) {
                // Applies Scale factor to calculate ROI's x and y values adjusted for the original image
                let I = Int(Double(i) * scale)
                let J = Int(Double(j) * scale)
                let w = Int(Double(ROI_SIZE.0) * scale)
                let h = Int(Double(ROI_SIZE.1) * scale)
                
                apiCall.enter() // Task Enters Dispatch Group before API Call Begins
                // Sends processed image to AI
                processAPICall(image: roiOrig, {(_, confidenceScore) in
                    // Appends Data to arrayOut if ROI has more than minimum confidence score
                    if confidenceScore >= MIN_CONFIDENCE_SCORE {
                        arrayOut.append( ((I, J, I+w, J+h), confidenceScore) )
                    }
                    apiCall.leave() // Task Leaves Dispatch Group after API call is completed
                    
                }) // END API CALL
                       
            } // END INNER FOR LOOP
        } // END OUTER FOR LOOP
        
        apiCall.notify(queue: .main, execute: {
            // (1) Lets all API calls complete
            // (2) Calls nonMaximumSuppression function to reduce overlapping rectangles
            // (3) Draws remaining rectangles on the image
            drawRectangleOnImage( nonMaximumSuppression(arrayOut) )
        })
    }
    
    func nonMaximumSuppression(_ infoArray:[((Int, Int, Int, Int), Double)]) -> [(Int, Int, Int, Int)]{
        var arrayNoOverlaps:[ ((Int, Int, Int, Int), Double) ] = []
        // Each index of arrayNoOverlaps contains a rectangle + confidenceScore tuple
        
        // Iterates through all entries in infoArray
        for ((x1,y1,x2,y2), confidenceScore) in infoArray {
            var overlapsOtherRectangle = false
            
            // Appends current info to array if overlapsOtherRectangle remains false
            // Compares to overlapping rectangle if overlapsOtherRectangle is true
            // Replaces current overlapping rectangle if confidence score is greater
            // Else, leaves arrayOut as is
            
            // Iterates through all current entries in arrayNoOverlaps if arrayNoOverlaps is not empty
            if !(arrayNoOverlaps.isEmpty) {
                for i in 0...arrayNoOverlaps.count-1 {
                    if isOverlapping(rect1: (x1,y1,x2,y2), rect2: arrayNoOverlaps[i].0) {
                        // Replaces current rectangle if confidence score is higher
                        if confidenceScore > arrayNoOverlaps[i].1 {
                            arrayNoOverlaps[i] = ((x1,y1,x2,y2), confidenceScore)
                        }
                        overlapsOtherRectangle = true
                    } // END IF STATEMENT
                } // END INNER FOR LOOP
            } // END IF STATEMENT
            
            // Appends current info if it does not overlap with any other rectangle
            if !overlapsOtherRectangle {
                arrayNoOverlaps.append(((x1,y1,x2,y2), confidenceScore))
            }
        }
        
        // Returns array of non-overlapping rectangle coordinates
        var arrayOut:[(Int, Int, Int, Int)] = []
        for (coordinates, _) in arrayNoOverlaps {
            arrayOut.append(coordinates)
        }
        return arrayOut
    }
    
    // Helper function to check if Rect1 overlaps with any rectangle in rectArray
    func isOverlapping(rect1: (Int,Int,Int,Int), rect2: (Int,Int,Int,Int)) -> Bool {
        let THRESH = 100 // Threshold added to detect overlaps
        
        // Returns False if Rectangles are not overlapping
        if !( (rect1.2+THRESH < rect2.0) || (rect2.2+THRESH < rect1.0) || (rect1.3+THRESH < rect2.1) || (rect2.3+THRESH < rect1.1) ) {
            return true
        }
        return false // Returns false if no collisions are detected
    }

    func drawRectangleOnImage(_ arrayIn:[(Int, Int, Int, Int)]) {
        let imageSize = inputImage!.size
        var editedInputImage:UIImage = inputImage!
                
        for (x1,y1,x2,y2) in arrayIn {
            let scale: CGFloat = 0
            UIGraphicsBeginImageContextWithOptions(imageSize, false, scale) // Begins Drawing
            editedInputImage.draw(at: CGPoint.zero) // Sets Starting Point at (0,0)
            let rectangle = CGRect(x: x1, y: y1, width: x2-x1, height: y2-y1) // Creates Rectangle Object at the correct x and y coordinates
            let color:UIColor = .systemPink // Sets Stroke Color
            color.set()
            
            // Draws Rectangle "Path" on top of UIImage
            let rect:UIBezierPath = UIBezierPath(rect: rectangle)
            rect.lineWidth = 4.5
            rect.stroke()
            editedInputImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext() // Ends Drawing
        }
        inputImage = editedInputImage // Replaces inputImage with inputImage with Rectangles
        self.loadingText = "" // Resets Loading Text
    }
    
    func convertToAgeGroup(_ prediction:String) -> String {
        switch prediction {
        case "Kid":
            return "6-20"
        case "Young Adult":
            return "21-35"
        case "Adult":
            return "36-59"
        case "Elderly":
            return "60+"
        default:
            return "Invalid Photo"
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


