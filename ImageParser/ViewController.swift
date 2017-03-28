//
//  ViewController.swift
//  ImageParser
//
//  Created by Wiliam Vabrinskas on 2/27/17.
//

import Cocoa

public struct File {
    var ext:String!
    var directory:String!
    var name:String!
    var realName:String!
}

class ViewController: NSViewController {
    @IBOutlet weak var testImageView: NSImageView!
    
    @IBOutlet weak var runAgainButton: NSButton!
    @IBOutlet weak var gradientView: NSView! {
        didSet {
            gradientView.wantsLayer = true
        }
    }
    @IBOutlet weak var elapsedLabel: NSTextField!
    @IBOutlet weak var averageColorLabel: NSTextField!
    @IBOutlet weak var colorView: NSView! {
        didSet {
            colorView.wantsLayer = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(gotFile(notification:)), name: NSNotification.Name.init(rawValue: "got_file"), object: nil)
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        colorView.layer!.borderWidth = 2.0
        colorView.layer!.borderColor = NSColor(deviceWhite: 0.6, alpha: 1.0).cgColor
        colorView.layer!.cornerRadius = 5.0
        runAgainButton.isEnabled = false
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    private func roundFloat(value: CGFloat,to place:CGFloat) -> CGFloat {
        return round(value * place) / place
    }
    
    private func parse(with image:NSImage) {
        runAgainButton.isEnabled = false

        Parser(with: image).parse(complete: { (color, time) in
            
            self.runAgainButton.isEnabled = true

            let solidColor = color["color"] as! NSColor
            let gradientColors = color["gradient"] as! [String:CGColor]
            
            self.colorView.layer!.backgroundColor = solidColor.cgColor
            
            let red = self.roundFloat(value: solidColor.redComponent, to: 100.0)
            let green = self.roundFloat(value: solidColor.greenComponent, to: 100.0)
            let blue = self.roundFloat(value: solidColor.blueComponent, to: 100.0)

            self.averageColorLabel.stringValue = "Average color: rgb(\(red), \(green), \(blue))"
            
            let gradient = CAGradientLayer()
            gradient.colors = [gradientColors["red"]!, gradientColors["green"]!, gradientColors["blue"]!]
            gradient.frame = self.gradientView.bounds
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
            
            if self.gradientView.layer?.sublayers != nil{
                self.gradientView.layer!.replaceSublayer(self.gradientView.layer!.sublayers![0], with: gradient)
            } else {
                self.gradientView.layer!.insertSublayer(gradient, at: 0)
            }
            
            self.elapsedLabel.stringValue = String.init(format: "Render time: %0.4fs", time)
        })
    }
    
    @IBAction func runAgain(_ sender: Any) {
        parse(with: testImageView.image!)
    }
    
    func gotFile(notification: Notification) {
        if let file = notification.object as? File {
            if let image = NSImage(contentsOfFile: file.directory) {
                testImageView.image = image
                self.parse(with: image)
            }
        }
    }
    
    
}

