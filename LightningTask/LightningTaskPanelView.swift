//
//  ContentView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//

import SwiftUI

struct LightningTaskPanelView: View {
    @State private var todo: String = ""
    @State private var suggestion: TaskSuggestion?
    @FocusState private var isFocused: Bool
    @State private var selected: String = ""
    @State private var showDatePicker = false
    @State private var alarmEnabled: Bool = true
    
    let panelController: LightningTaskPanelController
    let reminderViewModel: ReminderViewModel
    
    var suggestedDateValue: Date? {
        guard let suggestion else { return nil }
        let date = suggestion.dueDate
        let time = suggestion.dueTime
        if date.isEmpty && time.isEmpty { return nil }
        
        let today = String(ISO8601DateFormatter().string(from: .now).prefix(10))
        let dateString = date.isEmpty ? today : date
        let timeString = time.isEmpty ? "00:00" : time
        
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm"
        return parser.date(from: "\(dateString) \(timeString)")
    }
    
    var suggestedDate: String {
        guard let date = suggestedDateValue else { return "" }
        let hasTime = !(suggestion?.dueTime.isEmpty ?? true)
        let display = DateFormatter()
        display.dateFormat = hasTime ? "EE, d. MMM · HH:mm" : "EE, d. MMM"
        display.locale = Locale(identifier: "de_DE")
        return display.string(from: date)
    }
    
    /// Bindet den DatePicker direkt an `suggestion`. Schreibt nur, wenn der User
    /// im Picker tatsächlich etwas ändert — der initiale Anzeigewert triggert
    /// keinen Setter (im Gegensatz zu `@State pickerDate` + `onChange`).
    private var pickerBinding: Binding<Date> {
        Binding(
            get: { suggestedDateValue ?? .now },
            set: { newValue in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                suggestion?.dueDate = dateFormatter.string(from: newValue)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                suggestion?.dueTime = timeFormatter.string(from: newValue)
            }
        )
    }
    
    
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "bolt.circle")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.secondary)
                TextField("New Task", text: $todo, prompt: Text("New Task"))
                    .font(.system(size: 30))
                    .fontWeight(.semibold)
                    .focused($isFocused)
                    .textFieldStyle(.plain)  // no background
                    .tint(.white)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    }
                    .onKeyPress(.escape) {
                        panelController.close()
                        return .handled
                    }
                    .onKeyPress(keys: [.return]) { keyPress in
                        let commandPressed = keyPress.modifiers.contains(.command)
                       
                            Task {
                               let itemSaved = await reminderViewModel.saveCurrentItems(suggestion: suggestion, todo: todo, listname: selected, alarmEnabled: alarmEnabled)
                                if itemSaved {
                                    if commandPressed {
                                        suggestion = nil
                                        todo = ""
                                        selected = ""
                                        alarmEnabled = true
                                    } else {
                                        panelController.close()
                                    }
                                }
                            }
                            return .handled
                    }
                // task is set through swiftui
                    .task(id: todo) {
                        guard todo.count > 2, reminderViewModel.modelAvailable else { return }
                        try? await Task.sleep(for: .milliseconds(500))
                        guard !Task.isCancelled else { return }
                        suggestion = try? await reminderViewModel.suggestLists(for: todo)
                        selected = suggestion?.listNames.first ?? ""
                        alarmEnabled = true
                        print(suggestion ?? "")
                    }
            }
            // no if let suggestions, since i dont want a constant
            if suggestion != nil {
                Divider()
                VStack {
                    HStack(spacing: 7) {
                        ForEach(suggestion?.listNames ?? [], id: \.self) { item in
                            ChipView(item: item, isSelected: selected == item)
                                .onTapGesture {
                                    selected = item
                                }
                        }
                        Spacer()
                    }
                    
                    HStack {
                        if !suggestedDate.isEmpty && suggestedDate != "" {
                            ChipView(item: suggestedDate, isSelected: false)
                                .onTapGesture {
                                    showDatePicker.toggle()
                                }
                                .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                                    DatePicker("Date", selection: pickerBinding)
                                        .datePickerStyle(.stepperField)
                                        .padding()
                                }
                            AlarmButton(alarmEnabled: $alarmEnabled)
                            
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    LightningTaskPanelView(panelController: LightningTaskPanelController(), reminderViewModel: ReminderViewModel())
}
