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
    let panelController = LightningTaskPanelController()
    let hotKey = HotKey(key: .space, modifiers: [.control])
    
    
    init () {
        hotKey.keyDownHandler = { [panelController] in
            panelController.toggle()
        }
        // try to autologin on startup
        try? SMAppService.mainApp.register()
    }
    
    var body: some Scene { }
}
