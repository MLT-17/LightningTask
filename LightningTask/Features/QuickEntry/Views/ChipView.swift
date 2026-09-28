//
//  ChipView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 31.05.26.
//

import SwiftUI

struct ChipView: View {
    @Binding var item: String
    var isSelected: Bool
    var prefillOnEdit: Bool = false
    var editableField: EditableField? = nil
    @Binding var editingChip: EditableField?
    var action: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var editText: String = ""
    @FocusState private var isFocused: Bool
    
    init(item: Binding<String>, editableField: EditableField, editingChip: Binding<EditableField?>) {
        self._item = item
        self.isSelected = false
        self.prefillOnEdit = false
        self.editableField = editableField
        self._editingChip = editingChip
    }
    
    init(item: Binding<String>, isSelected: Bool, editingChip: Binding<EditableField?>, action: @escaping (() -> Void)) {
        self._item = item
        self.isSelected = isSelected
        self._editingChip = editingChip
        self.action = action
    }
    
    init(item: Binding<String>, prefillOnEdit: Bool, editableField: EditableField, editingChip: Binding<EditableField?>, onDelete: @escaping (() -> Void)) {
        self._item = item
        self.isSelected = false
        self.prefillOnEdit = prefillOnEdit
        self.editableField = editableField
        self._editingChip = editingChip
        self.onDelete = onDelete
    }
    
    var isEditing: Bool {
        guard let field = editableField else { return false }
        return editingChip == field
    }
    
    var isDateOrTimeChip: Bool {
        editableField == .date || editableField == .time
    }
    
    var hasValue: Bool {
        isDateOrTimeChip && !item.isEmpty
    }
    
    var isHighlighted: Bool {
        isDateOrTimeChip ? hasValue : isSelected
    }
    
    var displayText: String {
        guard isDateOrTimeChip, item.isEmpty else { return item }
        return editableField == .date ? String(localized: "chip_no_date") : String(localized: "chip_no_time")
    }
    
    var isEditable: Bool {
        return editableField != nil
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
                if isEditable {
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
                                editText = prefillOnEdit ? item : ""
                            }
                        }
                        .onSubmit {
                            if editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               let onDelete {
                                onDelete()
                            } else {
                                item = editText
                            }
                            editingChip = nil
                        }
                        .onKeyPress(.escape) {
                            if item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let onDelete {
                                onDelete()
                            }
                            
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
