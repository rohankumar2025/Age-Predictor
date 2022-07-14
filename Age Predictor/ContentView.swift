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
let AIURL = "https://askai.aiclub.world/018cb7b9-ad1c-4c60-84a1-267fac249865"

// Observable Object to store all global variables in
// Allows Object to be passed as an Environment Object
class GlobalVars : ObservableObject {
    @Published var doObjectDetection = true
    @Published var numAttemptsToDetectObj = 0
}

struct ContentView: View {
    @State private var predictedAgeGroup = ""
    
    @State private var showSheet = false
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    @State private var inputImage: UIImage? = UIImage(named: "default")
    @State private var loadingText = " "
    @State private var isLoading = false

    @StateObject var globals = GlobalVars() // Creates global varible object
    

    
    var body: some View {
        VStack {
            // All Views with Struct at the end of its name are in ViewStructs.swift
            HeaderView().environmentObject(globals) // Passes global variables to header view
            Spacer()
            PredictionTextStruct(predictedAgeGroup: self.$predictedAgeGroup)
            isLoading ? LoadingCircleStruct() : nil // Shows loading Circle if isLoading == true
            InputImageViewStruct(inputImage: self.$inputImage)
            Spacer()
            SubmitButtonStruct(showingImagePicker: self.$showSheet)
            Spacer()
        } // Action Sheet allowing User to select between using Camera Roll or Taking a Live photo
        .actionSheet(isPresented: self.$showSheet) {
            ActionSheet(title: Text("Select Photo"), buttons: [
                .default(Text("Photo Library")) {
                    self.showingImagePicker = true
                    self.sourceType = .photoLibrary // Sets source type to Camera Roll
                },
                .default(Text("Take Photo")) {
                    self.showingImagePicker = true
                    self.sourceType = .camera // Sets source type to Camera
                },
                .default(Text("Dismiss")) { self.showSheet = false }
            ] )
        }
        .fullScreenCover(isPresented: $showingImagePicker, onDismiss: processImage) { // Displays Image Picker with correct Source Type
            // TODO: FIX LIVE PHOTO. CANT SUBMIT PHOTO
            ImagePicker(image: self.$inputImage, isShown: self.$showingImagePicker, sourceType: self.sourceType)
                .ignoresSafeArea(.all)
        }
    }
    
    
    
    /// Is called after Submit Button is pressed and Image is selected.
    ///1. Turns off Image Picker.
    ///2. Processes API Call on entire image and outputs prediction.
    ///3. Applies Image Processing procedures on image.
    func processImage() {
        self.showingImagePicker = false // Removes Camera Roll Image picker from UI
        
        if let img = inputImage {
            img.detectFaces { (results) in
                guard let results = results else { return }
                var facesArray: [CGRect] = []
                for face in results {
                    facesArray.append(face.boundingBox)
                }
                inputImage = img.drawRectanglesOnImage(boundingBoxes: facesArray)
                
            }
        }
    }
    
    
    /// Processes API Call by sending image to global AI API link
    /// - parameter image: Image to be sent to AI API link.
    /// - parameter completion: completion handler to be executed using AI output once API call finishes.
    ///1. Is called on entire image to determine age range
    ///2. Is called on all subimages created by slidingWindow() function
    func processAPICall(image: UIImage, _
                        completion: @escaping (_ prediction:String, _ confidenceScore:Double) -> Void) {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


