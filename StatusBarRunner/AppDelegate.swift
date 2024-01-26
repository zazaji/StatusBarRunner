//
//  RunnersViewModel.swift
//  StatusBarRunner
//
//  Created by ou on 12/21/23.
//
import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel = RunnersViewModel()

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!

    static func quit() {
        NSApplication.shared.terminate(self)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 设置 popover
        popover = NSPopover()
        popover.contentSize = NSSize()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ProcessesView(viewModel: viewModel))

        // 设置状态栏图标
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem.button {
            button.title = "R"
            button.action = #selector(togglePopover(_:))
        }
    }

    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                viewModel.checkStatusAndUpdate()

                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
}
