//
//  ChipView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 31.05.26.
//

import SwiftUI

struct ChipView: View {
    var item: Binding<String>
    var isSelected: Bool
    var prefillOnEdit: Bool = false
    var editableField: EditableField? = nil
    @Binding var editingChip: EditableField?
    var action: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var editText: String = ""
    @FocusState private var isFocused: Bool
    
    var isEditing: Bool {
        guard let field = editableField else { return false }
        return editingChip == field
    }
    
    var isDateOrTime: Bool {
        return editableField == .date || editableField == .time
    }
    
    var hasValue: Bool {
        isDateOrTime && !item.wrappedValue.isEmpty
    }
    
    var isHighlighted: Bool {
        isDateOrTime ? hasValue : isSelected
    }
    
    var displayText: String {
        guard isDateOrTime, item.wrappedValue.isEmpty else { return item.wrappedValue }
        return editableField == .date ? String(localized: "chip_no_date") : String(localized: "chip_no_time")
    }
    
    var body: some View {
        
        Text(displayText)
            .font(.system(size: LayoutConstants.chipFontSize, weight: .medium))
            .foregroundColor(isEditing ? .clear : (isHighlighted ? Color("ChipGreen") : .secondary))
            .frame(minWidth: 30)
            .padding(.vertical, LayoutConstants.chipVerticalPadding)
            .padding(.horizontal, LayoutConstants.chipHorizontalPadding)
            .background(isHighlighted ? Color("ChipGreen").opacity(0.18) : .clear)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(
                isHighlighted ? Color("ChipGreen").opacity(0.5) : .white.opacity(0.18),
                lineWidth: isHighlighted ? LayoutConstants.chipSelectedBorderWidth : LayoutConstants.chipUnselectedBorderWidth
            ))
            .overlay {
                if editableField != nil {
                    TextField("", text: $editText)
                        .font(.system(size: LayoutConstants.chipFontSize, weight: .medium))
                        .textFieldStyle(.plain)
                        .padding(.vertical, LayoutConstants.chipVerticalPadding)
                        .padding(.horizontal, LayoutConstants.chipHorizontalPadding)
                        .focused($isFocused)
                        .allowsHitTesting(isEditing)
                        .opacity(isEditing ? 1 : 0)
                        .onChange(of: isEditing, initial: true) { _, editing in
                            isFocused = editing
                            if editing {
                                editText = prefillOnEdit ? item.wrappedValue : ""
                            }
                        }
                        .onSubmit {
                            if editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               let onDelete {
                                onDelete()
                            } else {
                                item.wrappedValue = editText
                            }
                            editingChip = nil
                        }
                        .onKeyPress(.escape) {
                            editingChip = nil
                            editText = ""
                            return .handled
                        }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let field = editableField {
                    editingChip = field
                } else {
                    action?()
                }
            }
        
        
    }
}
