//
//  InputImageViewStruct.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/14/22.
//

import Foundation
import SwiftUI

/// Displays InputImage passed in if it is not nil
struct InputImageViewStruct : View {
    @Binding var inputImage : UIImage? // Binds local inputImage to global inputImage
    @State var currentScale : CGFloat = 0
    @State var finalScale : CGFloat = 1
    
    @EnvironmentObject var globals : GlobalVars
    
    var body: some View {
        if let img = inputImage { // Optional binding to unwrap variable
            // Displays inputImage if not nil
            Image(uiImage: img).resizable()
                .aspectRatio(contentMode: .fill)
                // Adds pinch to zoom effect
                .scaleEffect(finalScale - currentScale)
                .gesture(MagnificationGesture()
                    .onChanged{ newScale in
                        // Scales image based on pinch
                        currentScale = 0.2 * newScale
                        self.globals.showButton = false // Removes "How Old Am I?" Button
                    }
                    .onEnded{ newScale in
                        // Returns image back to original size
                        currentScale = 0
                        self.globals.showButton = true // Adds "How Old Am I?" Button back
                    }
                )
        }
        
    }
}
