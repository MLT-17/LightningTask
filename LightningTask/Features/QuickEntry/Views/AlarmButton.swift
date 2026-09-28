//
//  AlarmButton.swift
//  LightningTask
//
//  Created by Matthias Tyca on 19.06.26.
//
import SwiftUI

struct AlarmButton: View {
    @Binding var alarmEnabled: Bool
    
    var body: some View {
        Button {
            alarmEnabled.toggle()
        } label: {
            // modifiers need to be on image since button has own tapgesture
            Image(systemName: alarmEnabled ? "bell.fill" : "bell")
                .font(.system(size: 12))
                .frame(width: 30, height: 30)
                .foregroundColor(alarmEnabled ? Color(red: 1, green: 0.27, blue: 0.22) : .white.opacity(0.3))
                .background(
                    Circle()
                        .fill(alarmEnabled ? Color(red: 1, green: 0.27, blue: 0.22).opacity(0.2) : .clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(alarmEnabled ? Color(red: 1, green: 0.27, blue: 0.22).opacity(0.45) : .white.opacity(0.18), lineWidth: 1.5)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        
        
    }
    
    
}


#Preview {
    AlarmButton(alarmEnabled: .constant(false))
        .padding(10)
}

#Preview {
    AlarmButton(alarmEnabled: .constant(true))
        .padding(10)
}
