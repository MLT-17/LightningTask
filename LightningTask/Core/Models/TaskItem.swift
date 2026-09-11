//
//  TaskItem.swift
//  LightningTask
//
//  Created by Matthias Tyca on 10.09.26.
//

import Foundation

struct TaskItem: Identifiable, Equatable {
    let id = UUID()
    var text: String
}
