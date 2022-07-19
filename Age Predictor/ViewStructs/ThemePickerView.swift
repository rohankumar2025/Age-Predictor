//
//  ThemePickerView.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/18/22.
//

import SwiftUI

let UIPink = Color.init(red: 1, green: 0.2, blue: 0.56) // Pink
let UIOrange = Color.init(red: 1, green: 0.64, blue: 0) // Orange
let UIGreen = Color.init(red: 0.06, green: 0.43, blue: 0.08) // Green


let colorsArray = [("Red", Color.red), ("Green", UIGreen), ("Orange", UIOrange), ("Pink", UIPink)]





struct ThemePickerView: View {
    @EnvironmentObject var globals : GlobalVars
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            ForEach(0..<colorsArray.count) { i in
                let currentlySelected = colorsArray[i].1 == self.globals.mainUIColor
                ZStack {
                    Rectangle()
                        .frame(width: 150, height: 50, alignment: .leading)
                        .foregroundColor(colorsArray[i].1)
                        .border(currentlySelected ? .white : .black)
                        .onTapGesture {
                            globals.mainUIColor = colorsArray[i].1
                        }
                    Text(colorsArray[i].0)
                        .foregroundColor(.white)
                        .font(.system(size: currentlySelected ? 25 : 20, weight: currentlySelected ? .bold : .regular ))
                }
            }
            Spacer()
            Spacer()
        }
        .padding()
        .background(self.globals.mainUIColor)
        
    }
}

struct ThemePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ThemePickerView()
            .environmentObject(GlobalVars())
    }
}
