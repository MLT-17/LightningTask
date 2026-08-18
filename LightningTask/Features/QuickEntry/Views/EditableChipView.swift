//
//  EditableChipView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 18.08.26.
//

import Foundation

//
//  ChipView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 31.05.26.
//

import SwiftUI

struct EditableChipView: View {
    var item: String
    var isSelected: Bool
    @FocusState private var isFocused: Bool
    @State private var editText: String = ""
    /// `isEditing` (not `isFocused`) drives the Text/TextField branch.
    /// Reason: `isFocused` can only focus a TextField that already exists.
    /// If the same variable both created the TextField AND requested focus,
    /// both would happen in the same state update — before SwiftUI has
    /// actually mounted the TextField as a responder. `isEditing` creates
    /// the TextField first; `.onAppear` requests focus a beat later, once
    /// it genuinely exists
    @State private var isEditing: Bool = false
    
    var body: some View {
     
            
            if !isEditing {
                Text(item)
                    .font(.system(size: LayoutConstants.chipFontSize, weight: .medium))
                    .foregroundColor(isSelected ? Color("ChipGreen") : .secondary)
                    .padding(.vertical, LayoutConstants.chipVerticalPadding)
                    .padding(.horizontal, LayoutConstants.chipHorizontalPadding)
                    .background(isSelected ? Color("ChipGreen").opacity(0.18) : .clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? Color("ChipGreen").opacity(0.5) : .white.opacity(0.18),
                                lineWidth: isSelected ? LayoutConstants.chipSelectedBorderWidth : LayoutConstants.chipUnselectedBorderWidth
                            )
                    )
                    .onTapGesture {
                        isEditing = true
                    }
            } else {
                TextField("", text: $editText)
                    .focused($isFocused)
                    .onAppear {
                        isFocused = true
                    }
                    .onSubmit {
                        isEditing = false
                    }
            }
     
    }
}

#Preview {
    EditableChipView(item: "Test", isSelected: false)
        .padding(16)
}

#Preview {
    EditableChipView(item: "Test", isSelected: true)
        .padding(16)
}

