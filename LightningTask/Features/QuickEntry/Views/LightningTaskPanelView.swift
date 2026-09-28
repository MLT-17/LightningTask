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
    // associated value for differenciating between item chips which is edited
    case item(UUID)
}

struct LightningTaskPanelView: View {
    @FocusState private var isFocused: Bool
    @State private var editingChip: EditableField?
    @State private var showSuccessFlash: Bool = false
    let onClose: () -> Void
    @Bindable var reminderViewModel: ReminderViewModel
    
    var successIndicatorIcon: String {
        if reminderViewModel.quickEntryError ==  .saveFailed {
            return "exclamationmark.circle"
        }
        return showSuccessFlash ? "checkmark.circle" :"bolt.circle"
    }
    
    var successIndicatorColor: Color {
        if reminderViewModel.quickEntryError == .saveFailed {
            return .red
        }
        return showSuccessFlash ? .chipGreen : .secondary
    }

    var body: some View {
        VStack {
            VStack {
                HStack(spacing: LayoutConstants.iconTextSpacing) {
                    Image(systemName: successIndicatorIcon)
                        .font(.system(size: LayoutConstants.boltIconSize, weight: .regular))
                        .foregroundStyle(successIndicatorColor)
                        .contentTransition(.symbolEffect(.replace))
                    TextField("", text: $reminderViewModel.todo, prompt: Text(String(localized: "new_task_placeholder")))
                        .frame(width: LayoutConstants.taskInputFieldWidth)
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
                            editingChip = nil
                            // Small delay needed for the panel to settle before accepting focus
                            Task {
                                try? await Task.sleep(for: .milliseconds(100))
                                isFocused = true
                            }
                        }
                        .onKeyPress(.escape) {
                            reminderViewModel.reset()
                            editingChip = nil
                            onClose()
                            return .handled
                        }
                        .onKeyPress(keys: [.return]) { keyPress in
                            
                            guard !reminderViewModel.isGeneratingSuggestion else {
                                return .handled
                            }
                            
                            let commandPressed = keyPress.modifiers.contains(.command)
                            
                            Task {
                                let itemSaved = await reminderViewModel.saveCurrentItems()
                                if itemSaved {
                                    withAnimation(.easeOut(duration: LayoutConstants.successAnimationDuration)) {
                                        showSuccessFlash = true
                                    }
                                   
                                    reminderViewModel.reset()
                                    editingChip = nil
                                    try? await Task.sleep(for: .seconds(LayoutConstants.successAnimationDuration))
                                    withAnimation(.easeOut(duration: LayoutConstants.successAnimationDuration)) {
                                        showSuccessFlash = false
                                    } completion: {
                                        if !commandPressed {
                                            onClose()
                                        }
                                    }
                                           
                                 
                                }
                            }
                            return .handled
                        }
                        .task(id: reminderViewModel.todo) {
                            await reminderViewModel.refreshSuggestion()
                        }
                }
                if let error = reminderViewModel.quickEntryError {
                    VStack(alignment: .leading) {
                        Divider()
                        Text(error.message)
                            .foregroundColor(.red)
                            .font(.caption)
                            .fontWeight(.bold)
                            
                    }
                    .padding(.leading, 8)
                }
                if let suggestion = reminderViewModel.suggestion {
                    if reminderViewModel.quickEntryError == nil {
                        Divider()
                    }
                    VStack(spacing: LayoutConstants.chipSpacing) {
                        
                        HStack(spacing: LayoutConstants.chipSpacing) {
                            ForEach($reminderViewModel.todoItems) { $item in
                                ChipView(item: $item.text, prefillOnEdit: true, editableField: .item(item.id), editingChip: $editingChip, onDelete:  {
                                    reminderViewModel.deleteTodoItem(with: item.id)
                                })
                            }
                            
                            AddButton {
                                editingChip = .item(reminderViewModel.addEmptyItem())
                            }
                            
                            Spacer()
                        }
                        
                        
                        HStack(spacing: LayoutConstants.chipSpacing) {
                            ForEach(suggestion.listNames, id: \.self) { item in
                                ChipView(item: .constant(item), isSelected: reminderViewModel.selected == item, editingChip: $editingChip, action: {
                                    reminderViewModel.selected = item
                                    editingChip = nil
                                })
                                
                            }
                            Spacer()
                        }
                        
                        HStack {
                            
                            
                            ChipView(item: $reminderViewModel.selectedDateText,  editableField: .date, editingChip: $editingChip)
                            
                            
                            ChipView(item: $reminderViewModel.selectedTimeText, editableField: .time, editingChip: $editingChip)
                            
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
            .overlay {
                if reminderViewModel.isGeneratingSuggestion || reminderViewModel.isSaving {
                    TimelineView(.animation) { timeline in
                        GeometryReader { geo in
                            let cornerRadius = LayoutConstants.panelCornerRadius
                            let dotLength: CGFloat = 240
                            let perimeter = 2 * (geo.size.width + geo.size.height) - 8 * cornerRadius + 2 * .pi * cornerRadius
                            let loopDuration: TimeInterval = 2.5
                            let elapsed = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: loopDuration)
                            let progress = elapsed / loopDuration
                            
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(
                                    Color.white.opacity(0.6),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [dotLength, max(perimeter - dotLength, 0)], dashPhase: -progress * perimeter)
                                )
                                .shadow(color: .white, radius: 4)
                        }
                    }
                }
            }
            .overlay {
                if showSuccessFlash {
                    RoundedRectangle(cornerRadius: LayoutConstants.panelCornerRadius)
                        .stroke(Color.chipGreen.opacity(0.5), lineWidth: 4)
                               .shadow(color: .chipGreen.opacity(0.5), radius: 6)
                               .transition(.opacity)
                }
            }
            Color.clear.frame(height: 4)
            
            
        }
        .overlay(alignment: .bottom) {
            ModeIndicatorChip(isGenerating: reminderViewModel.suggestion != nil || reminderViewModel.isGeneratingSuggestion)
                
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
