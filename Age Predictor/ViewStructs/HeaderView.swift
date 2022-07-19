//
//  HeaderView.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 6/23/22.
//

import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var globals : GlobalVars
    
    var body: some View {
        VStack {
            ZStack {
                
                // Background Color (Defined in ContentView)
                self.globals.mainUIColor.ignoresSafeArea()
                
                // App Title Text
                HStack {
                    // Displays app name text if side menu is not opened
                    Text(self.globals.themeMenuOpened ? "Age P..." : "Age Predictor")
                        .foregroundColor(.white)
                        .font(.system(size: 35))
                        .multilineTextAlignment(.center)
                        .offset(x: self.globals.themeMenuOpened ? -100 : 0)
                }
                
                // Information Button
                    Spacer()
                    Button(action: {
                        withAnimation(Animation.linear) {
                            self.globals.themeMenuOpened.toggle()
                        }
                        withAnimation(Animation.easeInOut(duration: 0.1)) {
                            self.globals.showButton.toggle()
                        }
                    }) {
                        ZStack {
                            HStack {
                                Spacer()
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 24, weight: .regular))
                                    .accentColor(.white)
                                    .padding()
                                    .offset(x: self.globals.themeMenuOpened ? -140 : -20)
                            }
                            HStack {
                                Spacer()
                                Text("Themes")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .offset(x: self.globals.themeMenuOpened ? -20 : 120)
                            }
                        }
                    }
            }
            .frame(height:60, alignment:.top)
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
            .environmentObject(GlobalVars())
    }
}
