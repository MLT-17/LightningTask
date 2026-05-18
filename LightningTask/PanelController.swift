//
//  PanelController.swift
//  LightningTask
//
//  Created by Matthias Tyca on 18.05.26.
//

import Foundation
import SwiftUI

class PanelController {
    private var panel: NSPanel?
    
    func toggle() {
        if let panel = self.panel, panel.isVisible {
            close()
        } else {
            open()
        }
    }
    
    func open() {
        let panel = NSPanel(
                contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )

            panel.isFloatingPanel = true
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.hidesOnDeactivate = false

            // SwiftUI-View einbinden
            let hostingView = NSHostingController(rootView: ContentView())
            panel.contentViewController = hostingView

            // Größe & Position
            let size = CGSize(width: 600, height: 80)
            panel.setContentSize(size)
            centerOnScreen(panel)

            panel.makeKeyAndOrderFront(nil)
            self.panel = panel
        
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(panelResignedKey),
                name: NSWindow.didResignKeyNotification,
                object: panel
            )

            panel.makeKeyAndOrderFront(nil)
            self.panel = panel
    }
    
    func close() {
        NotificationCenter.default.removeObserver(self)
        self.panel?.close()
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
