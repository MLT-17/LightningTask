//
//  AddButton.swift
//  LightningTask
//
//  Created by Matthias Tyca on 11.09.26.
//

import SwiftUI

struct AddButton: View {
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "plus")
        }
        .frame(width: 30, height: 30)
        .foregroundColor(.secondary)
        .overlay {
            Circle().strokeBorder(.white.opacity(0.18))
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}

#Preview {
    AddButton {
        print("Hi")
    }
}
