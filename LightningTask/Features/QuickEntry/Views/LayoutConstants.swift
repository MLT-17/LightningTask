//
//  LayoutConstants.swift
//  LightningTask
//
//  Created by Matthias Tyca on 13.05.26.
//

import Foundation

/// Centralized layout and design constants
enum LayoutConstants {
    
    // MARK: - Panel Dimensions
    
    /// Width of the quick-entry panel
    static let panelWidth: CGFloat = 600
    
    /// Minimum height of the panel (without suggestions)
    static let panelMinHeight: CGFloat = 80
    
    // MARK: - Typography
    
    /// Font size for the main task input field
    static let taskInputFontSize: CGFloat = 30
    
    /// Font size for the menu bar icon
    static let menuBarIconSize: CGFloat = 16
    
    /// Font size for the bolt icon in the panel
    static let boltIconSize: CGFloat = 28
    
    /// Font size for chip labels
    static let chipFontSize: CGFloat = 14
    
    // MARK: - Spacing
    
    /// Standard padding around the panel content
    static let panelPadding: CGFloat = 20
    
    /// Spacing between icon and text field
    static let iconTextSpacing: CGFloat = 12
    
    /// Spacing between chips
    static let chipSpacing: CGFloat = 7
    
    /// Vertical padding inside chips
    static let chipVerticalPadding: CGFloat = 8
    
    /// Horizontal padding inside chips
    static let chipHorizontalPadding: CGFloat = 16
    
    // MARK: - Border Widths
    
    /// Border width for selected chips
    static let chipSelectedBorderWidth: CGFloat = 1.5
    
    /// Border width for unselected chips
    static let chipUnselectedBorderWidth: CGFloat = 0.5
    
    // MARK: - Corner Radius
    
    /// Corner radius for the panel background
    static let panelCornerRadius: CGFloat = 16
}
