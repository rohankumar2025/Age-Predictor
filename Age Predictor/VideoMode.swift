//
//  VideoMode.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/14/22.
//

import SwiftUI

struct VideoMode: View {
    @EnvironmentObject var globals:GlobalVars // Global Variables Object
    @StateObject private var model = ContentViewModel() // ContentViewModel for video
    
    var body: some View {
        VStack {
            
            // Header for Video Mode
            ZStack {
                HStack {
                    Spacer()
                    // Button to Close Video Mode
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 25, weight: .semibold))
                        .offset(x:-10)
                        .onTapGesture (perform: {
                            // TODO: ADD ANIMATION
                            globals.videoModeEnabled = false
                        })
                }
                if model.shouldUpdatePredictions {
                    LoadingCircleStruct(scale: 1.8, color: .white)
                } else {
                    Text("Click Anywhere to See Age")
                    .font(.system(size: 25, weight: .light))
                    .foregroundColor(.white)
                }
                    
            }
            .padding(5)
            .background(self.globals.mainUIColor)
            
            // Error Frame (Displays Black Screen)
            if model.error != nil || model.frame == nil {
                // Error in Frame Model
                ZStack {
                    Rectangle()
                        .ignoresSafeArea()
                    Text("Camera unavailable")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .light))
                }
            } else {
                // Camera is functional
                // Displays Live Camera Model
                ZStack {
                    FrameView(image: model.frame)
                        .ignoresSafeArea()
                }
                .onTapGesture {
                    model.shouldUpdatePredictions = true
                }
                
                
            } // END IF-ELSE
        } // END VSTACK
    }
}

struct VideoMode_Previews: PreviewProvider {
    static var previews: some View {
        VideoMode()
            .environmentObject(GlobalVars())
    }
}
