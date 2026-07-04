//
//  LightningTaskApp.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//
import HotKey
import ServiceManagement // for autostart
import SwiftUI

@main
struct LightningTaskApp: App {
    // ✅ Single Source of Truth: Ein ViewModel für die gesamte App
    private let reminderViewModel = ReminderViewModel()
    
    // ✅ Controller bekommt das ViewModel injiziert
    private let panelController: LightningTaskPanelController
    
    let hotKey = HotKey(key: .space, modifiers: [.control])
    
    
    init () {
        // ✅ Dependency Injection: ViewModel wird an Controller übergeben
        panelController = LightningTaskPanelController(reminderViewModel: reminderViewModel)
        
        hotKey.keyDownHandler = { [panelController] in
            panelController.toggle()
        }
        // try to autologin on startup
        try? SMAppService.mainApp.register()
    }
    
    var body: some Scene { }
}
