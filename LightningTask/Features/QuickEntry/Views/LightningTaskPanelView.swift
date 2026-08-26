//
//  LightningTaskPanelView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//

import SwiftUI
enum EditableField: Hashable {
    case date
    case time
}

struct LightningTaskPanelView: View {
    @FocusState private var isFocused: Bool
    @State private var showDatePicker = false
    @State private var editingChip: EditableField?
    
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
                    .onChange(of: isFocused) { _, focused in
                            if focused {
                                editingChip = nil
                            }
                        }
                    .onAppear {
                        reminderViewModel.reset()
                        showDatePicker = false
                        editingChip = nil
                        // Small delay needed for the panel to settle before accepting focus
                        Task {
                            try? await Task.sleep(for: .milliseconds(100))
                            isFocused = true
                        }
                    }
                    .onKeyPress(.escape) {
                        reminderViewModel.reset()
                        showDatePicker = false
                        editingChip = nil
                        onClose()
                        return .handled
                    }
                    .onKeyPress(keys: [.return]) { keyPress in
                        let commandPressed = keyPress.modifiers.contains(.command)
                        
                        Task {
                            let itemSaved = await reminderViewModel.saveCurrentItems()
                            if itemSaved {
                                reminderViewModel.reset()
                                showDatePicker = false
                                editingChip = nil
                                if !commandPressed {
                                    onClose()
                                }
                            }
                        }
                        return .handled
                    }
                    .task(id: reminderViewModel.todo) {
                        await reminderViewModel.refreshSuggestion()
                    }
            }
            if let suggestion = reminderViewModel.suggestion {
                Divider()
                VStack(spacing: LayoutConstants.chipSpacing) {
                    
                    HStack(spacing: LayoutConstants.chipSpacing) {
                        ForEach(suggestion.items, id: \.self) { item in
                            ChipView(item: .constant(item), isSelected: false, editingChip: $editingChip)
                        }
                        Spacer()
                    }
                    
                    
                    HStack(spacing: LayoutConstants.chipSpacing) {
                        ForEach(suggestion.listNames, id: \.self) { item in
                            ChipView(item: .constant(item), isSelected: reminderViewModel.selected == item, editingChip: $editingChip)
                            {
                                reminderViewModel.selected = item
                                editingChip = nil
                            }
                        }
                        Spacer()
                    }
                    
                    HStack {
                        
                        
                        ChipView(item: $reminderViewModel.selectedDateText, isSelected: false, editableField: .date, editingChip: $editingChip)
                        
                        
                        ChipView(item: $reminderViewModel.selectedTimeText, isSelected: false, editableField: .time, editingChip: $editingChip)
                        
                        if !reminderViewModel.selectedDateText.isEmpty {
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
        .onChange(of: editingChip) { _, newValue in
            if newValue == nil {
                isFocused = true
            }
        }
    }
}

#Preview {
    let reminderViewModel = ReminderViewModel()
    return LightningTaskPanelView(
        onClose: { print("Panel closed") },
        reminderViewModel: reminderViewModel
    )
}
