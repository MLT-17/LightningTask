//
//  PanelController.swift
//  LightningTask
//
//  Created by Matthias Tyca on 18.05.26.
//

import Foundation
import SwiftUI

class LightningTaskPanel: NSPanel {
    // need to override because of warning in console
    // Warning: -[NSWindow makeKeyWindow] called on <NSPanel: 0x7a9c20000> windowNumber=3394 which returned NO from -[NSWindow canBecomeKeyWindow].
    // we want the panel to become key
    override var canBecomeKey: Bool { true }
}

class LightningTaskPanelController {
    private var panel: LightningTaskPanel?
    private var eventMonitor: Any?
    private var reminderViewModel: ReminderViewModel = ReminderViewModel()
    // use statusitem instead of menubarExtra.
    // Click on icon should just toggle panel, not open a menu
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    init() {
        let image = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: nil)
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        statusItem.button?.image = image?.withSymbolConfiguration(config)
        statusItem.button?.action = #selector(toggle)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp]) // use mouseup to toggle only after intentional click of user
        statusItem.button?.target = self
    }
    
    
    @objc func toggle() {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            // right click
            showContextMenu()
        } else {
            // left click
            if let panel = self.panel, panel.isVisible {
                close()
            } else {
                open()
            }
        }
    }
    
    @objc func showContextMenu() {
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit LightningTask", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        // opens the menu
        statusItem.button?.performClick(nil)
        // Detach menu so left click continues to trigger toggle
        statusItem.menu = nil
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    func open() {
        let panel = LightningTaskPanel(
            //initial rectangle. zero since we set contentSize below
            contentRect: .zero,
            // sets how panel looks and behave. to titlebar, not buttons when borderless set
            // nonavctivating: does not steal focus from active window
            styleMask: [.borderless, .nonactivatingPanel],
            // only value that is valid since macos 10
            backing: .buffered,
            // if there is delay in creating of panel. true is faster, but panel cannot be
            // configured right after
            defer: false
        )
        
        // stays above normal windows
        panel.isFloatingPanel = true
        // above other app windows, beneath system windows
        panel.level = .floating
        // not transparent
        panel.isOpaque = false
        // window background is transparent (for .thinmaterial to shine)
        panel.backgroundColor = .clear
        // shadow for deep effect
        panel.hasShadow = true
        // panel should be visible even if other app gets focus
        panel.hidesOnDeactivate = false
        // enable drag and drop
        panel.isMovableByWindowBackground = true
        
        // include SwiftUI-View
        let hostingView = NSHostingController(rootView: ContentView(panelController: self, reminderViewModel: reminderViewModel))
        panel.contentViewController = hostingView
        
        // size & position
        // contentSize is size WITH frame (but we don't have one here). if we had one
        // we would have to use "setFrameOrigin"
        let size = CGSize(width: 600, height: 80)
        panel.setContentSize(size)
        centerOnScreen(panel)
        // panel is key window (window that gets keyboard input) and is set to front
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
        
        // Globaler Monitor: reagiert auf Klicks AUSSERHALB der App
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
        
 
        
    }
    
    func close() {
        
        self.panel?.close()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    @objc private func panelResignedKey() {
        close()
    }
    
    private func centerOnScreen(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.midY - panelSize.height / 2
        
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
