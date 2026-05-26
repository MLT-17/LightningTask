//
//  ContentView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//

import SwiftUI

struct ContentView: View {
    @State private var task: String = ""
    @FocusState private var isFocused: Bool
    
    let panelController: LightningTaskPanelController
    let reminderViewModel: ReminderViewModel
    
    var body: some View {
        VStack {
            TextField("New Task", text: $task, prompt: Text("New Task"))
             
                .font(.system(size: 30))
                .fontWeight(.bold)
                .focused($isFocused)
                .textFieldStyle(.plain)  // no background
                .tint(.white)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
                .onSubmit {
                    Task {
                        await reminderViewModel.createReminder(text: task)
                        panelController.close()
                    }
                   
                }
                .onKeyPress(.escape) {
                    panelController.close()
                    return .handled
                }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView(panelController: LightningTaskPanelController(), reminderViewModel: ReminderViewModel())
}
