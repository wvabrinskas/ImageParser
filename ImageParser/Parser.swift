//
//  Parser.swift
//  ImageParser
//
//  Created by Wiliam Vabrinskas on 2/27/17.
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
    private var gradients: [[String:Color]] = [[String:Color]]()

    init(with testImage:NSImage) {
        super.init()
        image = testImage
    }
    
    private func analyze(imageRect: NSRect, complete:@escaping(_ color: Color, _ gradient: [String: Color]) -> ())  {
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            
            var imageRect = imageRect
            
            var greatestDifRed:(g: CGFloat, b: CGFloat) = (g:0.0 , b:0.0)
            var greatestDifGreen:(r: CGFloat, b: CGFloat)  = (r:0.0, b:0.0)
            var greatestDifBlue:(r: CGFloat, g: CGFloat)  = (r:0.0, g:0.0)
            
            var greenColor: Color = (r: 0, g: 0, b: 0)
            var redColor: Color = (r: 0, g: 0, b: 0)
            var blueColor: Color = (r: 0, g: 0, b: 0)
            
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
                                //red
                                if r - b > greatestDifRed.b && r > g {
                                    //set blue color
                                    greatestDifRed.b = r - b
                                    redColor = (r:r, g:redColor.g, b:b)
                                }
                                
                                if r - g > greatestDifRed.g && r > b {
                                    //set green color
                                    greatestDifRed.g = r - g
                                    redColor = (r: r, g:g, b: redColor.b)
                                }
                    
                                //only set the highest green value if its distance from the other two values is greater than previous
                                //green
                                if g - r > greatestDifGreen.r && g > r {
                                    //set red color
                                    greatestDifGreen.r = g - r
                                    greenColor = (r:r, g:g, b: greenColor.b)
                                }
                                
                                if g - b > greatestDifGreen.b && g > b {
                                    //set blue color
                                    greatestDifGreen.b = g - b
                                    greenColor = (r:greenColor.r, g:g, b:b)
                                }

                                //only set the highest blue value if its distance from the other two values is greater than previous
                                //blue
                                if b - r > greatestDifBlue.r && b > r {
                                    //set red color
                                    greatestDifBlue.r = b - r
                                    blueColor = (r:r, g:blueColor.g, b:b)
                                }
                                
                                if b - g > greatestDifBlue.g && b > g {
                                    //set green color
                                    greatestDifBlue.g = b - g
                                    blueColor = (r:blueColor.r, g:g, b:b)
                                }
                                
                                totalR = totalR + r
                                totalG = totalG + g
                                totalB = totalB + b
                                
                                totalCount = totalCount + 1

                            }
                            
                        }
                        
                        let gradientDict:[String:Color] = ["red": redColor, "green": greenColor, "blue": blueColor]

                        //get averages of colors for quadrant
                        let finalR = totalR / CGFloat(totalCount)
                        let finalG = totalG / CGFloat(totalCount)
                        let finalB = totalB / CGFloat(totalCount)
                        
                        complete((finalR,finalG,finalB), gradientDict)
                        
                    }
                }
            } //end of if*/
        }
    }
    
    private func createColorResult() -> ColorResult {
        let singleColor = solidColor()
        
        var newRed:CGFloat = 0.0
        var newGreen:CGFloat = 0.0
        var newBlue:CGFloat = 0.0
        
        var greenColor: Color = (r: 0, g: 0, b: 0)
        var redColor: Color = (r: 0, g: 0, b: 0)
        var blueColor: Color = (r: 0, g: 0, b: 0)
        
        for gradient in gradients {
            let redGradient = gradient["red"]!
            let greenGradient = gradient["green"]!
            let blueGradient = gradient["blue"]!
            
            //red
            if redGradient.r > newRed {
                newRed = redGradient.r
                redColor = (r: newRed, g: redGradient.g, b: redGradient.b)
            }
            
            //green
            if greenGradient.g > newGreen {
                newGreen = greenGradient.g
                greenColor = (r: greenGradient.r, g: newGreen, b: greenGradient.b)
            }
            
            //blue
            if blueGradient.b > newBlue {
                newBlue = blueGradient.b
                blueColor = (r: blueGradient.r, g: blueGradient.g, b: newBlue)
            }
        }
        
        
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
            self.analyze(imageRect: imageRect, complete: { (color,gradient) in
                self.results.append(color)
                self.gradients.append(gradient)
                
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
