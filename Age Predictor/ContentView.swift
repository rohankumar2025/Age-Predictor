//
//  ContentView.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 6/23/22.
//

import SwiftUI
import Alamofire
import SwiftyJSON

// comment
let UIPink = Color.init(red: 1, green: 0.2, blue: 0.56)

struct ContentView: View {
    @State var predictedAgeGroup = " "
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage? = UIImage(named: "default")
    
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
                    
                    if let i = inputImage { // IMAGE
                        Image(uiImage: i).resizable()
                        //.border(UIPink, width: 10)
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
        print("Button pressed")
        self.showingImagePicker = true
    }
    
    func processImage() {
        self.showingImagePicker = false
        self.predictedAgeGroup="..."
        guard let inputImage = inputImage else {return}
        print("Processing image due to Button press")
        let imageJPG=inputImage.jpegData(compressionQuality: 0.0034)!
        let imageB64 = Data(imageJPG).base64EncodedData()
        let uploadURL="https://askai.aiclub.world/018cb7b9-ad1c-4c60-84a1-267fac249865"
        
        AF.upload(imageB64, to: uploadURL).responseJSON { response in
            
            debugPrint(response)
            switch response.result {
            case .success(let responseJsonStr):
                //print("\n\n Success value and JSON: \(responseJsonStr)")
                let myJson = JSON(responseJsonStr)
                let predictedValue = myJson["predicted_label"].string
                
                let predictionMessage = predictedValue!
                self.predictedAgeGroup = convertToAgeGroup(predictionMessage)
            case .failure(let error):
                print("\n\n Request failed with error: \(error)")
            }
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

    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        //picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
