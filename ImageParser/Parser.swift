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
typealias ColorResult = [String:Any]
typealias GradientColors = [NSColor]

class Parser: NSObject {
    
    private var image:NSImage!
    private var results: [Color] = [Color]()
    private var gradient: [[String:Color]] = [[String:Color]]()
    
    private var highestGreen:CGFloat = 0.0
    private var highestBlue:CGFloat = 0.0
    private var highestRed:CGFloat = 0.0
    
    //tuples to hold the differences in each RGB values as compared to one another
    private var greatestDifRed:(g:CGFloat,b:CGFloat) = (g:0.0 , b:0.0)
    private var greatestDifGreen:(r:CGFloat,b:CGFloat) = (r:0.0, b:0.0)
    private var greatestDifBlue:(r:CGFloat,g:CGFloat) = (r:0.0, g:0.0)
    
    private var greenColor: Color = (r: 0, g: 0, b: 0)
    private var redColor: Color = (r: 0, g: 0, b: 0)
    private var blueColor: Color = (r: 0, g: 0, b: 0)
    
    init(with testImage:NSImage) {
        super.init()
        image = testImage
    }
    
    private func analyze(imageRect: NSRect, complete:@escaping(_ result: Color) -> ())  {
        var imageRect = imageRect
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
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

                        //green if g is greater than r and b 
                        //red if r is greater than g and b 
                        //blue if b is greater than r and g
                        
                        for x in imgX..<width {
                            for y in imgY..<height {
                                
                                let pixelInfo: Int = ((width * y) + x) * 4
                                
                                let r = CGFloat(data[pixelInfo])
                                let g = CGFloat(data[pixelInfo + 1])
                                let b = CGFloat(data[pixelInfo + 2])
                                
                                //only set the highest red value if its distance from the other two values is greater than previous
                                if r - b > self.greatestDifRed.b && r - g > self.greatestDifRed.g {
                                    self.greatestDifRed.b = r - b
                                    self.greatestDifRed.g = r - g
                                    
                                    self.highestRed = r
                                    self.redColor = (r: self.highestRed, g:g, b: b)
                                }
                                
                                //only set the highest green value if its distance from the other two values is greater than previous
                                if g - r > self.greatestDifGreen.r && g - b > self.greatestDifGreen.b {
                                    self.greatestDifGreen.r = g - r
                                    self.greatestDifGreen.b = g - b
                                    
                                    self.highestGreen = g
                                    self.greenColor = (r: r, g:self.highestGreen, b: b)
                                }

                                //only set the highest blue value if its distance from the other two values is greater than previous
                                if b - r > self.greatestDifBlue.r &&  b - g > self.greatestDifBlue.g {
                                    self.greatestDifBlue.r = b - r
                                    self.greatestDifBlue.g = b - g
                                    
                                    self.highestBlue = b
                                    self.blueColor = (r: r, g:g, b: self.highestBlue)
                                }
                                
                                totalR = totalR + r
                                totalG = totalG + g
                                totalB = totalB + b
                                
                                totalCount = totalCount + 1
                                
                            }
                            
                        }
                        
                        //get averages of colors for quadrant
                        let finalR = totalR / CGFloat(totalCount)
                        let finalG = totalG / CGFloat(totalCount)
                        let finalB = totalB / CGFloat(totalCount)
                        
                        complete((finalR,finalG,finalB))
                        
                    }
                }
            } //end of if*/
        }
    }
    
    private func createColorResult() -> ColorResult {
        let singleColor = solidColor()
        
        let red = NSColor(deviceRed: redColor.r / 255.0, green: redColor.g / 255.0, blue: redColor.b / 255.0, alpha: 1.0)
        let green = NSColor(deviceRed: greenColor.r / 255.0, green: greenColor.g / 255.0, blue: greenColor.b / 255.0, alpha: 1.0)
        let blue = NSColor(deviceRed: blueColor.r / 255.0, green: blueColor.g / 255.0, blue: blueColor.b / 255.0, alpha: 1.0)
        
        let colorResult:ColorResult = ["color" : singleColor, "gradient" : ["red": red.cgColor, "green" : green.cgColor, "blue" : blue.cgColor]]
        
        return colorResult

    }

    
    private func solidColor() -> NSColor {
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
    
    public func parse(complete:@escaping(_ color: ColorResult, _ time: Double) -> ()) {
        var elapsed = Date().timeIntervalSince1970
        
        var frames:[CGRect] = [CGRect]()
        
        //separate image into quadrants and analyze those asyncronously
        for w in 0...1 {
            for h in 0...1 {
                let rect = CGRect(x:(self.image.size.width / 2) * CGFloat(w), y:(self.image.size.height / 2) * CGFloat(h), width: self.image.size.width / 2, height: self.image.size.height / 2)
                frames.append(rect)
            }
        }
        
        for imageRect in frames {
            self.analyze(imageRect: imageRect, complete: { (result) in
                self.results.append(result)
                
                if self.results.count == frames.count {
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
                        elapsed = Date().timeIntervalSince1970 - elapsed
                        complete(self.createColorResult(), elapsed)
                    })
                }
            })
        }
        
    }
}
