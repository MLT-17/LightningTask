//
//  LightningTaskApp.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//

import SwiftUI

@main
struct LightningTaskApp: App {
    var body: some Scene {
//        MenuBarExtra {
//            ContentView()
//        }
        MenuBarExtra {
            ContentView()
        } label: {
            Image(systemName: "checklist")
        }
        .menuBarExtraStyle(.window)

    }
}
