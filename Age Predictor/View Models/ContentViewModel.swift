/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import CoreImage
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var error: Error?
    @Published var frame: CGImage?
    var shouldUpdatePredictions = false
    
    private let context = CIContext()
    
    private let cameraManager = CameraManager.shared
    private let frameManager = FrameManager.shared
    
    private var predictionLabel:String = "" // TEMPORARY STRING
    private var previousNumFaces = 0
    
    init() {
        setupSubscriptions()
    }
    
    func setupSubscriptions() {
        cameraManager.$error
            .receive(on: RunLoop.main)
            .map { $0 }
            .assign(to: &$error)
        
        frameManager.$current
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                guard let image = CGImage.create(from: buffer) else {
                    return nil
                }
                
                
                // Output Image
                var cgImageOut:CGImage = image // CGImage to be outputted for Frame
                var uiImage = UIImage(cgImage: cgImageOut) // UIImage created from CGImage (to have rectangles drawn on it)
                
                let faceDetection = DispatchGroup()
                
                faceDetection.enter()
                uiImage.detectFaces{ results in
                    guard let results = results else { return } // Unwraps results from Vision AI
                    
                    var facesArray:[(CGRect, String)] = [] // Array holding all faces information
                    for face in results {
                        if self.shouldUpdatePredictions {
                            let subImage = uiImage.croppedTo(boundingBox: face.boundingBox)
                            subImage.processAPICall{ (prediction, _) in // Sends cropped subimage to API
                                self.predictionLabel = prediction
                                self.shouldUpdatePredictions = false
                            }
                        }
    
                        facesArray.append((face.boundingBox, self.predictionLabel)) // Adds all face boundingBoxes to facesArray
                    }
                    uiImage = uiImage.drawRectsAndLabelsOnImage(boundingBoxArray: facesArray, mode: 0) // Draws all boundingBoxes and labels on image
                    
                    
                    // Unwraps and converts uiImage back into a cgImage
                    guard let cgImg = uiImage.cgImage else { return }
                    cgImageOut = cgImg
                    faceDetection.leave()
                }
                
                faceDetection.wait() // Waits for faceDetection to complete before returning value
                return cgImageOut
            }
            .assign(to: &$frame)
    }
}
