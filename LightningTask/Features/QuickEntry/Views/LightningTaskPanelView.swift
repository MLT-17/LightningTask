//
//  LightningTaskPanelView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//

import SwiftUI

struct LightningTaskPanelView: View {
    @FocusState private var isFocused: Bool
    @State private var showDatePicker = false

    // Inversion of Control: Only the action, not the whole controller
    let onClose: () -> Void
    @Bindable var reminderViewModel: ReminderViewModel

    var body: some View {
        VStack {
            HStack(spacing: LayoutConstants.iconTextSpacing) {
                Image(systemName: "bolt.circle")
                    .font(.system(size: LayoutConstants.boltIconSize, weight: .regular))
                    .foregroundStyle(.secondary)
                TextField("", text: $reminderViewModel.todo, prompt: Text(String(localized: "new_task_placeholder")))
                    .font(.system(size: LayoutConstants.taskInputFontSize))
                    .fontWeight(.semibold)
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .tint(.white)
                    .onAppear {
                        // Reset when opening the panel
                        reminderViewModel.reset()
                        showDatePicker = false
                        
                        // Use Swift Concurrency instead of DispatchQueue hack
                        Task {
                            try? await Task.sleep(for: .milliseconds(100))
                            isFocused = true
                        }
                    }
                    .onKeyPress(.escape) {
                        // Reset before closing
                        reminderViewModel.reset()
                        showDatePicker = false
                        onClose()
                        return .handled
                    }
                    .onKeyPress(keys: [.return]) { keyPress in
                        let commandPressed = keyPress.modifiers.contains(.command)

                            Task {
                               let itemSaved = await reminderViewModel.saveCurrentItems()
                                if itemSaved {
                                    // Always reset, then decide whether to close
                                    reminderViewModel.reset()
                                    showDatePicker = false
                                    
                                    if !commandPressed {
                                        // Normal Return → close
                                        onClose()
                                    }
                                    // Cmd+Return → keep open for next input
                                }
                            }
                            return .handled
                    }
                // Task is set through SwiftUI
                    .task(id: reminderViewModel.todo) {
                        await reminderViewModel.refreshSuggestion()
                    }
            }
            // Use if let instead of optional chaining
            if let suggestion = reminderViewModel.suggestion {
                Divider()
                VStack {
                    HStack(spacing: LayoutConstants.chipSpacing) {
                        ForEach(suggestion.listNames, id: \.self) { item in
                            ChipView(item: item, isSelected: reminderViewModel.selected == item)
                                .onTapGesture {
                                    reminderViewModel.selected = item
                                }
                        }
                        Spacer()
                    }

                    HStack {
                        let dateString = reminderViewModel.suggestedDateString(for: suggestion)
                        if !dateString.isEmpty {
                            ChipView(item: dateString, isSelected: false)
                                .onTapGesture {
                                    showDatePicker.toggle()
                                }
                                .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                                    DatePicker(String(localized: "date_picker_label"), selection: $reminderViewModel.selectedDate)
                                        .datePickerStyle(.stepperField)
                                        .padding()
                                }
                            AlarmButton(alarmEnabled: $reminderViewModel.alarmEnabled)

                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(LayoutConstants.panelPadding)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial.opacity(0.85), in: RoundedRectangle(cornerRadius: LayoutConstants.panelCornerRadius))
    }
}

#Preview {
    let reminderViewModel = ReminderViewModel()
    return LightningTaskPanelView(
        onClose: { print("Panel closed") },
        reminderViewModel: reminderViewModel
    )
}

