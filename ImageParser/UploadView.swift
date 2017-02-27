//
//  UploadView.swift
//  BynderUploader
//
//  Created by Wiliam Vabrinskas on 1/19/17.
//  Copyright © 2017 Elite Daily. All rights reserved.
//

import Foundation
import AppKit


class UploadView: NSView {
    
    let expectedExt = ["png","jpg","mpg","mpeg","mp4","gif","pdf","txt","rtf"]  //file extensions allowed for Drag&Drop
    var file: File?

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer!.backgroundColor = NSColor.white.cgColor
        register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType])
        
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        //self.layer?.backgroundColor = NSColor.white.cgColor
        //NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "hide_cover"), object: nil)
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        //self.layer?.backgroundColor = NSColor.white.cgColor
        Swift.print("dragging ended")
        //NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "hide_cover"), object: nil)
    }


    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        //self.layer?.backgroundColor = NSColor.gray.cgColor
       // NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "show_cover"), object: nil)
       // NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "show_cover_loading"), object: nil)

        return NSDragOperation.generic
    }
    
    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let path = board[0] as? String
            else { return false }
        
        let suffix = URL(fileURLWithPath: path).pathExtension
        for ext in self.expectedExt {
            if ext.lowercased() == suffix {
                return true
            }
        }
        return false
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray
        else { return false }
        
        for paste in pasteboard {
            if let path = paste as? String {
                let suffix = URL(fileURLWithPath: path).pathExtension
                let name = URL(fileURLWithPath: path).lastPathComponent
                if self.expectedExt.contains(suffix.lowercased()) {
                    file = File()
                    file!.ext = suffix
                    file!.directory = path
                    file!.name = name
                    file!.realName = name.components(separatedBy: ".")[0]
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "got_file"), object: file!)
                } else {
                    Swift.print("file cannot be uploaded")
                }
            }
        }
        return true
    }

}
