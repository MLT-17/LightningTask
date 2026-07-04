//
//  PanelController.swift
//  LightningTask
//
//  Created by Matthias Tyca on 18.05.26.
//

import Foundation
import Sparkle
import SwiftUI

class LightningTaskPanel: NSPanel {
    // Override to prevent console warning:
    // "Warning: -[NSWindow makeKeyWindow] called on <NSPanel: 0x...> which returned NO from -[NSWindow canBecomeKeyWindow]"
    // We want the panel to become the key window
    override var canBecomeKey: Bool { true }
}

class LightningTaskPanelController {
    private var panel: LightningTaskPanel?
    private var eventMonitor: Any?
    
    // ✅ Dependency Injection: ViewModel wird von außen übergeben
    private let reminderViewModel: ReminderViewModel
    
    private let updaterController: SPUStandardUpdaterController
    
    // Use NSStatusItem instead of SwiftUI MenuBarExtra
    // Clicking the icon should toggle the panel, not open a menu
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    /// Initializes the panel controller with injected dependencies
    /// - Parameter reminderViewModel: The view model managing reminder state and operations
    init(reminderViewModel: ReminderViewModel) {
        self.reminderViewModel = reminderViewModel
        
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, // Start updater on initialization
            // Hooks for customization of behavior and UI (nil = use defaults)
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        let image = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: nil)
        let config = NSImage.SymbolConfiguration(pointSize: LayoutConstants.menuBarIconSize, weight: .regular)
        statusItem.button?.image = image?.withSymbolConfiguration(config)
        statusItem.button?.action = #selector(toggle)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp]) // Use mouse up to toggle only after intentional click
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
        
        // Version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

        let versionItem = NSMenuItem(
            title: "Version \(version) (\(build))",
            action: nil,
            keyEquivalent: ""
        )
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        menu.addItem(NSMenuItem.separator())
        
        // Update
        let updateItem = NSMenuItem(
            title: "Nach Updates suchen…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)
        // Quit
        let quitItem = NSMenuItem(title: "Quit LightningTask", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
       
        statusItem.menu = menu
        // opens the menu
        statusItem.button?.performClick(nil)
        // Detach menu so left click continues to trigger toggle
        statusItem.menu = nil
    }
    
    @objc func checkForUpdates() {
        updaterController.updater.checkForUpdates()
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
        // ✅ Inversion of Control: View bekommt Closure statt Controller
        let hostingView = NSHostingController(
            rootView: LightningTaskPanelView(
                onClose: { [weak self] in
                    self?.close()
                },
                reminderViewModel: reminderViewModel
            )
        )
        panel.contentViewController = hostingView
        
        // Size & position
        // contentSize is the size WITH frame (but we don't have one here)
        // If we had a frame, we would use "setFrameOrigin"
        let size = CGSize(width: LayoutConstants.panelWidth, height: LayoutConstants.panelMinHeight)
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
        // ✅ Reset state before closing
        reminderViewModel.reset()
        
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
