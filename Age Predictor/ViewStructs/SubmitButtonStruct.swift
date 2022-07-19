//
//  SubmitButtonStruct.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/11/22.
//

import Foundation
import SwiftUI


/// Displays SubmitButton which turns on ImagePicker when pressed
/// Used in Picture Mode
struct SubmitButtonStruct : View {
    @Binding var toggle : Bool // Binds local showingImagePicker variable to global showingImagePicker
    @Binding var mainUIColor : Color
    
    
    var body: some View {
        Button("How Old Am I?"){
            toggle = true // Turns on ImagePicker sheet
        }
        .padding(.all, 14.0)
        .background(mainUIColor)
        .foregroundColor(.white)
        .cornerRadius(10)
        .font(.title)
        .shadow(color: .black, radius: 1)
    }
}

