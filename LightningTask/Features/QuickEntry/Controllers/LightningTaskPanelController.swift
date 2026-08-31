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

    private let reminderViewModel: ReminderViewModel

    private let updaterController: SPUStandardUpdaterController

    // NSStatusItem instead of MenuBarExtra — clicking toggles the panel rather than opening a menu
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    /// Initializes the panel controller with injected dependencies
    /// - Parameter reminderViewModel: The view model managing reminder state and operations
    init(reminderViewModel: ReminderViewModel) {
        self.reminderViewModel = reminderViewModel

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
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
            showContextMenu()
        } else {
            if let panel = self.panel, panel.isVisible {
                close()
            } else {
                open()
            }
        }
    }

    @objc func showContextMenu() {
        let menu = NSMenu()

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

        let updateItem = NSMenuItem(
            title: String(localized: "menu_check_for_updates"),
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)

        let quitItem = NSMenuItem(title: String(localized: "menu_quit"), action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
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
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear // required for .thinMaterial to render
        panel.hasShadow = true
        panel.hidesOnDeactivate = false // keep visible when another app is focused
        panel.isMovableByWindowBackground = true

        let hostingView = NSHostingController(
            rootView: LightningTaskPanelView(
                onClose: { [weak self] in
                    self?.close()
                },
                reminderViewModel: reminderViewModel
            )
        )
        panel.contentViewController = hostingView

        let size = CGSize(width: LayoutConstants.panelWidth, height: LayoutConstants.panelMinHeight)
        panel.setContentSize(size)
        centerOnScreen(panel)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel

        // Closes panel on clicks outside the app
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    func close() {
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
