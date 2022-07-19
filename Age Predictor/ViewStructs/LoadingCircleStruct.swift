//
//  LoadingCircleStruct.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/14/22.
//

import Foundation
import SwiftUI

/// Displays animated circles when program is processing its API calls
struct LoadingCircleStruct : View {
    
    var scale:Double
    var color:Color
    
    init(scale:Double = 1.5, color:Color) {
        self.scale = scale
        self.color = color
    }
    
    
    var body: some View {
        // Loading Circle View
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: self.color))
            .scaleEffect(self.scale)
        
    }
}
