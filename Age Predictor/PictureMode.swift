//
//  PictureMode.swift
//  Age Predictor
//
//  Created by Rohan Kumar on 7/15/22.
//

import SwiftUI

struct PictureMode: View {
    
    @EnvironmentObject var globals: GlobalVars
    @EnvironmentObject var cameraSettings: CameraSettingsObj
    
    var body: some View {
        VStack {
            HeaderView().environmentObject(globals)
            Spacer()
            ZStack {
                InputImageViewStruct(inputImage: self.$globals.inputImage)
                    .ignoresSafeArea()
                    .environmentObject(globals)
                VStack {
                    Spacer()
                    self.globals.isLoading ? LoadingCircleStruct(scale: 1.5, color: self.globals.mainUIColor).offset(y:-10) : nil
                    self.globals.showButton ? SubmitButtonStruct(toggle: self.$cameraSettings.showSheet, mainUIColor: self.$globals.mainUIColor) : nil
                }
                HStack {
                    Spacer()
                    ThemePickerView()
                        .offset(x: self.globals.themeMenuOpened ? -60 : 400)
                }


            }
        }
    }
}

struct PictureMode_Previews: PreviewProvider {
    static var previews: some View {
        PictureMode()
            .environmentObject(GlobalVars())
            .environmentObject(CameraSettingsObj())
    }
}
