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

class Parser: NSObject {
    
    class func parse(image: NSImage, complete:@escaping(_ color: NSColor) -> ()) {
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            var imageRect:CGRect = CGRect(x:0, y:0, width: image.size.width, height: image.size.height)
            if let coreImage = image.cgImage(forProposedRect: &imageRect, context: NSGraphicsContext.current(), hints: nil) {
                if let pixelData = coreImage.dataProvider?.data {
                    if let data:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData) {
                        
                        let height = Int(image.size.height)
                        let width = Int(image.size.width)
                        
                        var totalR:CGFloat = 0
                        var totalG:CGFloat = 0
                        var totalB:CGFloat = 0
                        
                        var totalCount = 0
                        for x in 0..<width {
                            for y in 0..<height {
                                var pixelInfo: Int = ((width * y) + x) * 4
                                
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
                        
                        let color = NSColor(deviceRed: finalR / 255.0, green: finalG / 255.0, blue: finalB / 255.0, alpha: 1.0)
                        
                        complete(color)
                    }
                }
            }
        }
    }
}
