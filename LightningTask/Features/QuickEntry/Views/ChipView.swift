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
    var editableField: EditableField? = nil
    @Binding var editingChip: EditableField?
    var action: (() -> Void)? = nil
    
    @State private var editText: String = ""
    @FocusState private var isFocused: Bool
    
    var isEditing: Bool {
        guard let field = editableField else { return false }
        return editingChip == field
    }
    
    var hasValue: Bool {
        editableField != nil && !item.wrappedValue.isEmpty
    }
    
    var isHighlighted: Bool {
        editableField != nil ? hasValue : isSelected
    }
    
    var displayText: String {
        guard editableField != nil, item.wrappedValue.isEmpty else { return item.wrappedValue }
        return editableField == .date ? String(localized: "chip_no_date") : String(localized: "chip_no_time")
    }
    
    var body: some View {
        
        Text(displayText)
            .font(.system(size: LayoutConstants.chipFontSize, weight: .medium))
            .foregroundColor(isEditing ? .clear : (isHighlighted ? Color("ChipGreen") : .secondary))
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
                        .onChange(of: isEditing) { _, editing in
                            isFocused = editing
                            if editing {
                                editText = ""
                            }
                        }
                        .onSubmit {
                            item.wrappedValue = editText
                            editingChip = nil
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
