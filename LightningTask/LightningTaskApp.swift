//
//  LightningTaskApp.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//

import SwiftUI

@main
struct LightningTaskApp: App {
    let panelController = PanelController()
    
    var body: some Scene {
        MenuBarExtra {
            Button("Open") { panelController.toggle() }
                        Divider()
                        Button("Quit") { NSApp.terminate(nil) }
        } label: {
            Image(systemName: "bolt.circle")
        }
        .menuBarExtraStyle(.window)

    }
}
