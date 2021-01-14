//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import SwiftUI

extension SlideOverPanel {
    /// Modifier to update cummulative width of the panel. 
    /// - Parameter `width`:  defaults to screen size
    /// - Returns: `SlideOverPanel`
    func width(_ width: CGFloat) -> SlideOverPanel {
        return SlideOverPanel(slideOutPanelWidth: width,
                              actionOnBackgroundTap: actionOnBackgroundTap,
                              content: content,
                              backgroundDimmed: backgroundDimmed,
                              direction: direction,
                              tokens: tokens,
                              transitionState: $transitionState,
                              percentTransition: $percentTransition)
    }

    /// Update or replace content on panel
    /// - Parameter `drawerContent`: View to replace content
    /// - Returns: `SlideOverPanel`
    func withContent(_ drawerContent: Content) -> SlideOverPanel {
        return SlideOverPanel(slideOutPanelWidth: slideOutPanelWidth,
                              actionOnBackgroundTap: actionOnBackgroundTap,
                              content: drawerContent,
                              backgroundDimmed: backgroundDimmed,
                              direction: direction,
                              tokens: tokens,
                              transitionState: $transitionState,
                              percentTransition: $percentTransition)
    }

    /// Add action or callback to be executed when background view is Tapped
    /// - Parameter `performOnBackgroundTap`:  defaults to no-op
    /// - Returns: `SlideOverPanel`
    func performOnBackgroundTap(_ performOnBackgroundTap: (() -> Void)?) -> SlideOverPanel {
        return SlideOverPanel(slideOutPanelWidth: slideOutPanelWidth,
                              actionOnBackgroundTap: performOnBackgroundTap,
                              content: content,
                              backgroundDimmed: backgroundDimmed,
                              direction: direction,
                              tokens: tokens,
                              transitionState: $transitionState,
                              percentTransition: $percentTransition)
    }

    /// Add opacity to background view
    /// - Parameter `opacity`: defaults to clear with no opacity
    /// - Returns: `SlideOverPanel`
    func isBackgroundDimmed(_ value: Bool) -> SlideOverPanel {
        return SlideOverPanel(slideOutPanelWidth: slideOutPanelWidth,
                              actionOnBackgroundTap: actionOnBackgroundTap,
                              content: content,
                              backgroundDimmed: value,
                              direction: direction,
                              tokens: tokens,
                              transitionState: $transitionState,
                              percentTransition: $percentTransition)
    }

    /// Change opening direction for slideout
    /// - Parameter `direction`: defaults to left
    /// - Returns: `SlideOverPanel`
    func direction(_ slideOutDirection: SlideOverDirection) -> SlideOverPanel {
        return SlideOverPanel(slideOutPanelWidth: slideOutPanelWidth,
                              actionOnBackgroundTap: actionOnBackgroundTap,
                              content: content,
                              backgroundDimmed: backgroundDimmed,
                              direction: slideOutDirection,
                              tokens: tokens,
                              transitionState: $transitionState,
                              percentTransition: $percentTransition)
    }
}
