//
//  LightningTaskApp.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//
import HotKey
import os
import ServiceManagement // for autostart
import SwiftUI

@main
struct LightningTaskApp: App {
    private let reminderViewModel = ReminderViewModel()
    private let panelController: LightningTaskPanelController
    private let logger = Logger(subsystem: "de.mlt.LightningTask", category: "LightningTaskApp")

    let hotKey = HotKey(key: .space, modifiers: [.control])


    init () {
        panelController = LightningTaskPanelController(reminderViewModel: reminderViewModel)

        hotKey.keyDownHandler = { [panelController] in
            panelController.toggle()
        }
        do {
            try SMAppService.mainApp.register()
            logger.info("✅ Login item status: \(String(describing: SMAppService.mainApp.status))")
        } catch {
            logger.error("❌ Failed to register login item: \(error)")
        }
    }
    
    var body: some Scene { }
}
