//
//  ViewController.swift
//  ImageParser
//
//  Created by Wiliam Vabrinskas on 2/27/17.
//  Copyright © 2017 Elite Daily. All rights reserved.
//

import Cocoa

public struct File {
    var ext:String!
    var directory:String!
    var name:String!
    var realName:String!
}

class ViewController: NSViewController {
    @IBOutlet weak var gradientView: NSView! {
        didSet {
            gradientView.wantsLayer = true
        }
    }
    @IBOutlet weak var elapsedLabel: NSTextField!

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

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func gotFile(notification: Notification) {
        if let file = notification.object as? File {
            let image = NSImage(contentsOfFile: file.directory)
            Parser(with: image!).parse(complete: { (color, time) in
                let solidColor = color["color"] as! NSColor
                let gradientColors = color["gradient"] as! [String:CGColor]
                
                self.colorView.layer!.backgroundColor = solidColor.cgColor
                
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
    }


}

