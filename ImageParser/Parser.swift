//
//  Parser.swift
//  ImageParser
//
//  Created by Wiliam Vabrinskas on 2/27/17.
//  Copyright © 2017 Elite Daily. All rights reserved.
//

import Foundation
import QuartzCore
import AppKit

typealias Color = (r: CGFloat, g: CGFloat, b: CGFloat)

class Parser: NSObject {
    
    var image:NSImage!
    var results: [Color] = [Color]()
    let notificationName = NSNotification.Name.init(rawValue: "completed_parsing")
    
    init(with testImage:NSImage) {
        super.init()
        image = testImage
    }
    
    func analyze(imageRect: NSRect, complete:@escaping(_ result: Color) -> ())  {
        var imageRect = imageRect
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            if let coreImage = self.image.cgImage(forProposedRect: &imageRect, context: NSGraphicsContext.current(), hints: nil) {
                if let pixelData = coreImage.dataProvider?.data {
                    if let data:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData) {
                        
                        let height = Int(self.image.size.height)
                        let width = Int(self.image.size.width)
                        let imgX = Int(imageRect.origin.x)
                        let imgY = Int(imageRect.origin.y)
                        
                        var totalR:CGFloat = 0
                        var totalG:CGFloat = 0
                        var totalB:CGFloat = 0
                        
                        var totalCount = 0
                        
                        for x in imgX..<width {
                            for y in imgY..<height {
                                
                                let pixelInfo: Int = ((width * y) + x) * 4
                                
                                let r = CGFloat(data[pixelInfo])
                                let g = CGFloat(data[pixelInfo + 1])
                                let b = CGFloat(data[pixelInfo + 2])
                                
                                
                                totalR = totalR + r
                                totalG = totalG + g
                                totalB = totalB + b
                                
                                totalCount = totalCount + 1
                                
                            }
                        }
                        
                        //get averages of colors
                        let finalR = totalR / CGFloat(totalCount)
                        let finalG = totalG / CGFloat(totalCount)
                        let finalB = totalB / CGFloat(totalCount)
                        
                        complete((finalR,finalG,finalB))
                        
                    }
                }
            } //end of if*/
        }
    }
    
    func color() -> NSColor {
        var totalR:CGFloat = 0
        var totalG:CGFloat = 0
        var totalB:CGFloat = 0
        
        for result in results {
            
            let r = result.r
            let g = result.g
            let b = result.b
            
            totalR = totalR + r
            totalG = totalG + g
            totalB = totalB + b
        }
        
        let finalR = totalR / CGFloat(results.count)
        let finalG = totalG / CGFloat(results.count)
        let finalB = totalB / CGFloat(results.count)
        
        let analyzedColor = NSColor(deviceRed: finalR / 255.0, green: finalG / 255.0, blue: finalB / 255.0, alpha: 1.0)
        return analyzedColor
    }
    
    func parse(complete:@escaping(_ color: NSColor, _ time: Double) -> ()) {
        var elapsed = Date().timeIntervalSince1970
        
        var frames:[CGRect] = [CGRect]()
        
        for w in 0...1 {
            for h in 0...1 {
                let rect = CGRect(x:(self.image.size.width / 2) * CGFloat(w), y:(self.image.size.height / 2) * CGFloat(h), width: self.image.size.width / 2, height: self.image.size.height / 2)
                frames.append(rect)
                print(rect)
            }
        }
        
        for imageRect in frames {
            self.analyze(imageRect: imageRect, complete: { (result) in
                self.results.append(result)
                print(result)
                if self.results.count == frames.count {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
                        elapsed = Date().timeIntervalSince1970 - elapsed
                        complete(self.color(), elapsed)
                    })
                }
            })
        }
        
        
    }
}
