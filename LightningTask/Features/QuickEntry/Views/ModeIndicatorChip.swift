//
//  ModeIndicatorChip.swift
//  LightningTask
//
//  Created by Matthias Tyca on 22.09.26.
//

import SwiftUI

struct ModeIndicatorChip: View {
    let isGenerating: Bool
    
    var body: some View {
        // The ZStack is needed otherwise whole "Chip" will be transitioned instead of only the text
        ZStack {
            Text(isGenerating ? String(localized: "mode_ai") : String(localized: "mode_lightning"))
                .id(isGenerating) // this is needed to tell SwiftUI View ist changing, not just text for the transition to take effect
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
        }
        .frame(width: 100, height: 15)
        .clipped()
        .animation(.linear, value: isGenerating)
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .glassEffect(in: Capsule())
    }
    
}

#Preview {
    ModeIndicatorChip(isGenerating: false)
}
