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
    
    
    let chipGreen = Color(red: 0.298, green: 0.851, blue: 0.392)
    
    var body: some View {
        Text(item)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? chipGreen : .secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? chipGreen.opacity(0.18) : .clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? chipGreen.opacity(0.5) : .white.opacity(0.18),
                        lineWidth: isSelected ? 1.5 : 0.5
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

