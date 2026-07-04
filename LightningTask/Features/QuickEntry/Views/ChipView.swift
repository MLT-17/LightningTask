//
//  ChipView.swift
//  LightningTask
//
//  Created by Matthias Tyca on 31.05.26.
//

import SwiftUI

struct ChipView: View {
    let item: String
    var isSelected: Bool
    
    var body: some View {
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
    }
}

#Preview {
    ChipView(item: "Test", isSelected: false)
        .padding(16)
}

#Preview {
    ChipView(item: "Test", isSelected: true)
        .padding(16)
}

