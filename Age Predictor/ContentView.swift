//
//  ContentView.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 6/23/22.
//

import UIKit
import SwiftUI
import Alamofire
import SwiftyJSON

let AIURL = "https://askai.aiclub.world/018cb7b9-ad1c-4c60-84a1-267fac249865"

// Observable Object to store all global variables in
// Allows Object to be passed as an Environment Object
class GlobalVars : ObservableObject {
    @Published var videoModeEnabled = false // Used to determine whether or not to show Video Mode screen
    @Published var inputImage:UIImage? = UIImage(named: "default") // Holds inputImage used for processing in Photo Mode
    @Published var showButton = true // Used to determine whether or not to show "How Old Am I?" button
    @Published var isLoading = false // Used to determine whether or not to show Loading Circles
    @Published var mainUIColor = Color.init(red: 1, green: 0.2, blue: 0.56) // Used to hold UIColor based on chosen theme
    @Published var themeMenuOpened = false // Used to determine whether or not to show theme side menu
}

// Observable Object to store state of Camera and Sheets
class CameraSettingsObj : ObservableObject {
    @Published var showingImagePicker = false // Used to determine whether or not to show image picker
    @Published var showSheet = false // Used to determine whether or not to show sheet to navigate between Photo, Camera Roll, and Video modes
    @Published var pictureType:UIImagePickerController.SourceType = .photoLibrary // Used to determine source type for Picture Mode (Options: photoLibrary and camera)
}



struct ContentView: View {
    @StateObject var globals = GlobalVars() // Creates global variable object
    @StateObject var cameraSettings = CameraSettingsObj() // Creates camera settings object
    
    var body: some View {
        VStack {
            // Navigates between Video Mode and Photo Mode
            if self.globals.videoModeEnabled {
                VideoMode()
            } else {
                PictureMode()
            }
        }
        // Passes both environment Objects to VideoMode and PictureMode views
        .environmentObject(self.globals)
        .environmentObject(self.cameraSettings)
        .background(self.globals.mainUIColor)
        
        // Action Sheet allowing User to select between using Camera Roll or Taking a Live photo
        .actionSheet(isPresented: self.$cameraSettings.showSheet) {
            ActionSheet(title: Text("Choose your photo mode"), buttons: [
                .default(Text("Photo Library")) {
                    // Shows image picker in photoLibrary mode
                    self.cameraSettings.showingImagePicker = true
                    self.cameraSettings.pictureType = .photoLibrary
                },
                .default(Text("Take a Photo")) {
                    // Shows image picker in camera mode
                    self.cameraSettings.showingImagePicker = true
                    self.cameraSettings.pictureType = .camera
                },
                .default(Text("Live Video (beta)")) {
                    // Enables Video Mode
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.globals.videoModeEnabled = true
                    }
                },
                .cancel() // Cancel button to close sheet
            ] )
            
        }
        // Full Screen Cover displaying image picker if enabled
        .fullScreenCover(isPresented: self.$cameraSettings.showingImagePicker, onDismiss: processImage) {
            ImagePicker(image: self.$globals.inputImage, isShown: self.$cameraSettings.showingImagePicker, sourceType: self.cameraSettings.pictureType)
                .ignoresSafeArea(.all)
        }
    }
    
    
    
    /// Is called after Submit Button is pressed and Image is selected.
    ///1. Turns off Image Picker.
    ///2. Processes Vision AI on image and processes Age AI on all faces found
    ///3. Outputs face recognition using bounding boxes
    ///4. Displays labels for each face's age range
    func processImage() {
        self.cameraSettings.showingImagePicker = false // Removes Camera Roll Image picker from UI
        guard let img = self.globals.inputImage else { return } // Unwraps inputImage
        self.globals.isLoading = true
        
        // Calls Vision AI detectFaces function to find all faces in picture
        img.detectFaces { (results) in
            guard let results = results else { return } // Unwraps results of Vision AI
            var facesArray: [(CGRect, String)] = []
            var predictions:[String] = []
            
            let apiCall = DispatchGroup()
            
            for i in 0...results.count-1 {
                let face = results[i]
                // Creates subimage based off boundingBox outputted for current face
                let subImage = img.croppedTo(boundingBox: face.boundingBox)
                // Temporarily populates predictionArray with empty strings
                predictions.append("")
                
                // Sends subimage to Age API and processes results
                apiCall.enter()
                subImage.processAPICall{ (prediction, _) in
                    predictions[i] = prediction // Assigns prediction to correct index in array
                    apiCall.leave()
                }
                // Adds current face boundingBox to faceArray
                facesArray.append((face.boundingBox, ""))
            }
            
            // Draws all rectangles and empty labels on image (BEFORE API CALLS HAVE PROCESSED)
            DispatchQueue.main.async {
                self.globals.inputImage = img.drawRectsAndLabelsOnImage(boundingBoxArray: facesArray, mode: 1)
            }
            
            apiCall.notify(queue: .main) {
                // Adds info from API calls to facesArray
                for i in 0...facesArray.count-1 {
                    facesArray[i].1 = predictions[i]
                }
                // Draws all updated labels and boundingBoxes
                self.globals.inputImage = img.drawRectsAndLabelsOnImage(boundingBoxArray: facesArray, mode: 1)
                self.globals.isLoading = false
            }
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 13 Pro Max")
            .previewInterfaceOrientation(.portrait)
        ContentView()
            .previewDevice("iPhone 8")
            .previewInterfaceOrientation(.portrait)
    }
}


