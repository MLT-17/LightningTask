//
//  LightningTaskApp.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//
import HotKey
import SwiftUI

@main
struct LightningTaskApp: App {
    let panelController = LightningTaskPanelController()
    let hotKey = HotKey(key: .t, modifiers: [.command])
    
    init () {
        hotKey.keyDownHandler = { [panelController] in
            panelController.toggle()
        }
    }
    
    var body: some Scene { }
}
