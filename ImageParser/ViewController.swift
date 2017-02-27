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
            Parser.parse(image: image!, complete: { (color) in
                self.colorView.layer!.backgroundColor = color.cgColor
            })
        }
    }


}

