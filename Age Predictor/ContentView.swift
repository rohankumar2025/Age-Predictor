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
                        self.buttonPressed()
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
    
    func buttonPressed() {
        self.showingImagePicker = true
    }
    
    func processImage() {
        self.showingImagePicker = false // Removes Camera Roll Image picker from UI
        self.predictedAgeGroup="..." // Temporary Message while AI is loading
        guard let inputImage = inputImage else {return} // Unwraps inputImage
        // Compresses and Converts image to correct output type
        let imageJPG=inputImage.jpegData(compressionQuality: 0.0034)!
        let imageB64 = Data(imageJPG).base64EncodedData()
        // Sends image to AI URL
        let uploadURL="https://askai.aiclub.world/018cb7b9-ad1c-4c60-84a1-267fac249865"
        AF.upload(imageB64, to: uploadURL).responseJSON { response in
            // Receives output from AI
            switch response.result {
            case .success(let responseJsonStr):
                let myJson = JSON(responseJsonStr)
                let predictedValue = myJson["predicted_label"].string // Parses Result for predicted value
                let confidence = Array(myJson["score"]) // Parses Result for all 4 confidence scores
                
                // Saves highest Confidence Score (corresponds to score of predicted label)
                var maxConfidenceScore:Double = 0
                for (_, c2) in confidence {
                    if ((c2.rawValue as! Double) > maxConfidenceScore) { maxConfidenceScore = c2.rawValue as! Double}
                }

                self.predictedAgeGroup = convertToAgeGroup(predictedValue!) // returns result, which is displayed on UI
            case .failure(let error):
                print("\n\n Request failed with error: \(error)")
            }
        }
        self.loadingText = "Detecting Objects..."
        detectObjsInImage(image: inputImage)
    }
    
    
    func detectObjsInImage(image: UIImage) /* -> [(UIImage, (Int, Int, Int, Int), String)]  */ {
        // initialize constants used for the object detection procedure
        let PYR_SCALE = 2.0 // Scale factor used in imagePyramid() function (Higher Value = faster, less accurate) (Lower value = slower, more accurate)
        let WIN_STEP = 20 // Size of step that the Sliding Window is taking
        let ROI_SIZE = (200, 200) // Dimensions of Sliding Window (Should be close in size to the object trying to be found)
        let uploadURL="https://askai.aiclub.world/018cb7b9-ad1c-4c60-84a1-267fac249865" // AI URL
        let MIN_CONFIDENCE_SCORE = 0.90 // Threshold value for rectangle to be drawn
        let INPUT_SIZE = (image.size.width, image.size.height) // Dimensions of Original Image

        var arrayOut:[(UIImage, (Int, Int, Int, Int), String)] = [] // Array containing [ ( ROI_image, (X+Y Coordinates for rectangle), prediction ) ]
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
                
                // Processing roiOrig before sending it into AI for processing
                let roiJPG=roiOrig.jpegData(compressionQuality: 0.0034)!
                let roiB64 = Data(roiJPG).base64EncodedData()
                
                apiCall.enter() // Task Enters Dispatch Group before API Call Begins
                // Sends processed image to AI
                AF.upload(roiB64, to: uploadURL).responseJSON { response in
                    switch response.result {
                    case .success(let responseJsonStr):
                        let myJson = JSON(responseJsonStr) // Converts response into JSON Format
                        let prediction = myJson["predicted_label"].string! // Parses response to find prediction
                        
                        // Calculates confidence score of prediction
                        let confidence = Array(myJson["score"])
                        var confidenceScore:Double = 0
                        for (_, c2) in confidence {
                            if ((c2.rawValue as! Double) > confidenceScore) { confidenceScore = c2.rawValue as! Double}
                        }
                        
                        // Appends Data to arrayOut if ROI has more than minimum confidence score
                        if confidenceScore >= MIN_CONFIDENCE_SCORE {
                            arrayOut.append( (roiOrig, (I, J, I+w, J+h), prediction) )
                        }
                    case .failure:
                        print("Failure")
                    } // END SWITCH-CASE STATEMENT
                    apiCall.leave() // Task Leaves Dispatch Group after API call is completed
                } // END UPLOAD
            } // END INNER FOR LOOP
        } // END OUTER FOR LOOP
        
        
        apiCall.notify(queue: .main, execute: {
            drawRectangleOnImage(arrayOut) // Calls drawRectangleOnImage function when all API calls are completed
        })
    }

    func drawRectangleOnImage(_ infoArray:[(UIImage, (Int, Int, Int, Int), String)]) {
        let imageSize = inputImage!.size
        var editedInputImage:UIImage = inputImage!
        
        for (_, (x1,y1,x2,y2), _) in infoArray {
            let scale: CGFloat = 0
            UIGraphicsBeginImageContextWithOptions(imageSize, false, scale) // Begins Drawing
            editedInputImage.draw(at: CGPoint.zero) // Sets Starting Point at (0,0)
            let rectangle = CGRect(x: x1, y: y1, width: x2-x1, height: y2-y1) // Creates Rectangle Object at the correct x and y coordinates
            // Sets Stroke Color
            let color:UIColor = .systemPink
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

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
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


