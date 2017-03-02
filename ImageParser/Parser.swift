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
    
    var image:NSImage!
    var results: [Color] = [Color]()
    var gradient: [[String:Color]] = [[String:Color]]()
    
    init(with testImage:NSImage) {
        super.init()
        image = testImage
    }
    
    private func analyze(imageRect: NSRect, complete:@escaping(_ result: Color, _ gradients: [String:Color]) -> ())  {
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
                    
                        
                        var highestGreen:CGFloat = 0.0
                        var highestBlue:CGFloat = 0.0
                        var highestRed:CGFloat = 0.0
                        
                        var greenColor: Color = (r: 0, g: 0, b: 0)
                        var redColor: Color = (r: 0, g: 0, b: 0)
                        var blueColor: Color = (r: 0, g: 0, b: 0)
                        //green if g is greater than r and b 
                        //red if r is greater than g and b 
                        //blue if b is greater than r and g
                        
                        let adjustment:CGFloat = 10.0
                        
                        for x in imgX..<width {
                            for y in imgY..<height {
                                
                                let pixelInfo: Int = ((width * y) + x) * 4
                                
                                let r = CGFloat(data[pixelInfo])
                                let g = CGFloat(data[pixelInfo + 1])
                                let b = CGFloat(data[pixelInfo + 2])
                                
                                if g > b + adjustment && g > r + adjustment {
                                    if g > highestGreen {
                                        highestGreen = g
                                        greenColor = (r: r, g:highestGreen, b: b)
                                    }
                                }
                                
                                if r > b + adjustment && r > g + adjustment {
                                    if r > highestRed {
                                        highestRed = r
                                        redColor = (r: highestRed, g:g, b: b)

                                    }
                                }
                                
                                if b > r + adjustment && b > g + adjustment {
                                    if b > highestBlue {
                                        highestBlue = b
                                        blueColor = (r: r, g:g, b: highestBlue)

                                    }
                                }

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
                        
                        complete((finalR,finalG,finalB), ["red" : redColor, "green" : greenColor, "blue" : blueColor])
                        
                    }
                }
            } //end of if*/
        }
    }
    
    private func createColorResult() -> ColorResult {
        let solidColor = color()
        
        var redColor: NSColor = .white
        var greenColor: NSColor = .green
        var blueColor: NSColor = .white
        
        var redR: CGFloat = 0
        var greenR: CGFloat = 0
        var blueR: CGFloat = 0
        
        var redG: CGFloat = 0
        var greenG: CGFloat = 0
        var blueG: CGFloat = 0
        
        var redB: CGFloat = 0
        var greenB: CGFloat = 0
        var blueB: CGFloat = 0
        
        var tempColors = [UnsafeMutablePointer<CGFloat>]()
        
        for gradientColor in gradient {
            
            tempColors.removeAll()
            
            redR = redR + gradientColor["red"]!.r
            blueR = blueR + gradientColor["red"]!.g
            greenR = greenR + gradientColor["red"]!.b

            redG = redG + gradientColor["green"]!.r
            blueG = blueG + gradientColor["green"]!.g
            greenG = greenG + gradientColor["green"]!.b
            
            redB = redB + gradientColor["blue"]!.r
            blueB = blueB + gradientColor["blue"]!.g
            greenB = greenB + gradientColor["blue"]!.b
            
            tempColors.append(&redR)
            tempColors.append(&blueR)
            tempColors.append(&greenR)
            tempColors.append(&redG)
            tempColors.append(&blueG)
            tempColors.append(&greenG)
            tempColors.append(&redB)
            tempColors.append(&blueB)
            tempColors.append(&greenB)
        }
        
        
        tempColors.forEach { (colorPointer) in
            colorPointer.pointee = colorPointer.pointee / CGFloat(gradient.count)
        }
        
        redColor = NSColor(deviceRed: redR / 255.0, green: greenR / 255.0, blue: blueR / 255.0, alpha: 1.0)
        greenColor = NSColor(deviceRed: redG / 255.0, green: greenG / 255.0, blue: blueG / 255.0, alpha: 1.0)
        blueColor = NSColor(deviceRed: redB / 255.0, green: greenB / 255.0, blue: blueB / 255.0, alpha: 1.0)
        
        print(redColor)
        print(greenColor)
        print(blueColor)

        let colorResult:ColorResult = ["color" : solidColor, "gradient" : ["red": redColor.cgColor, "green" : greenColor.cgColor, "blue" : blueColor.cgColor]]
        
        return colorResult

    }

    
    private func color() -> NSColor {
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
            self.analyze(imageRect: imageRect, complete: { (result, gradient) in
                self.results.append(result)
                self.gradient.append(gradient)
                
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
