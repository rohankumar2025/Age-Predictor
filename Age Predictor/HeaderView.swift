//
//  HeaderView.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 6/23/22.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        ZStack {
            UIPink.ignoresSafeArea()
        HStack {
            
            Button(action: {
                print("Information")
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 24, weight: .regular))
                    .accentColor(.white)
            }
            
            Text("    Age Predictor         ")
                .foregroundColor(.white)
                .font(.system(size: 35))
            
//            Button(action: {
//                print("Information")
//            }) {
//                Image(systemName: "line.3.horizontal")
//                    .font(.system(size: 24, weight: .regular))
//                    .accentColor(.white)
//            }
            
            
        }
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
            .previewLayout(.fixed(width: 375, height: 80))
    }
}
