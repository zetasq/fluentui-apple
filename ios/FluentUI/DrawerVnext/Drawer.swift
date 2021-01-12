//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import SwiftUI

// MARK: - Drawer Model

@objc public enum DrawerDirection: Int, CaseIterable {
    /// Drawer originates from left
    case left
    /// Drawer originates from right
    case right
}

/// `DrawerState` assist to configure drawer functional properties via UIKit components.
@objc(DrawerState)
public class DrawerState: NSObject, ObservableObject {

    /// A callback executed when the drawer is expanded/collapsed
    public var onStateChange: (() -> Void)?

    /// Set `isExpanded` to `true` to maximize the drawer's width to fill the device screen horizontally minus the safe areas.
    /// Set to `false` to restore it to the normal size.
    @Published public var isExpanded: Bool? {
        didSet {
            if isExpanded != oldValue {
                onStateChange?()
            }
        }
    }

    @objc public var presentationDirection: DrawerDirection = .left

    /// Set `backgroundDimmed` to `true` to dim the spacer area between drawer and base view.
    /// If set to `false` it restores to `clear` color
    @objc @Published public var backgroundDimmed: Bool = false

    /// anitmation duration when drawer is collapsed/expanded
    @objc public var animationDuration: Double = 0.0

    /// override this value to explicity set drag offset for the drawer
    @Published public var translation: (state: UIGestureRecognizer.State, point: CGPoint)?

    /// Set `presentingGesture` before calling `present` to provide a gesture recognizer that resulted in the presentation of the drawer and to allow this presentation to be interactive.
    public var presentingGesture: UIPanGestureRecognizer? {
        didSet {
            if presentingGesture == oldValue {
                return
            }
            oldValue?.removeTarget(self, action: #selector(handlePresentingPan))
            presentingGesture?.addTarget(self, action: #selector(handlePresentingPan))
        }
    }

    @objc private func handlePresentingPan(gesture: UIPanGestureRecognizer) {
        translation = (state: gesture.state, point: gesture.translation(in: gesture.view))
        if gesture.state == .ended {
            translation = nil
        }
    }
}

// MARK: - Drawer Token

/// `DrawerTokens` assist to configure drawer apperance via UIKit components.
public class DrawerTokens: MSFTokensBase, ObservableObject {

    @Published public var shadowColor: Color!
    @Published public var shadowOpacity: Double!
    @Published public var shadowBlur: CGFloat!
    @Published public var shadowDepthX: CGFloat!
    @Published public var shadowDepthY: CGFloat!
    @Published public var backgroundDimmedColor: Color!
    @Published public var backgroundClearColor: Color!
    @Published public var backgroundDimmedOpacity: CGFloat!
    @Published public var backgroundClearOpacity: CGFloat!

    public override init() {
        super.init()

        self.themeAware = true
        updateForCurrentTheme()
    }

    @objc open func didChangeAppearanceProxy() {
        updateForCurrentTheme()
    }

    public override func updateForCurrentTheme() {
        let appearanceProxy = theme.DrawerTokens

        shadowColor = Color(appearanceProxy.shadowColor)
        shadowOpacity = Double(appearanceProxy.shadowOpacity)
        shadowBlur = appearanceProxy.shadowBlur
        shadowDepthX = appearanceProxy.shadowX
        shadowDepthY = appearanceProxy.shadowY
        backgroundClearColor = Color(appearanceProxy.backgroundClearColor)
        backgroundDimmedColor = Color(appearanceProxy.backgroundDimmedColor)
        backgroundDimmedOpacity = appearanceProxy.backgroundDimmedOpacity
        backgroundClearOpacity = appearanceProxy.backgroundClearOpacity
    }
}

// MARK: - Drawer

/// `Drawer` is used to present a overlay a content partially on another view.
/// `Drawer`  support horizontal axis and is expanded by default from left side of the screen unless explicitly specified
///  Set `Content` to provide content for the drawer.
public struct Drawer<Content: View>: View {

    /// content view on top of `Drawer`
    public var content: Content

    @Environment(\.theme) var theme: FluentUIStyle

    /// configure the behavior of drawer
    @ObservedObject public var state = DrawerState()

    /// configure the apperance of drawer
    @ObservedObject public var tokens = DrawerTokens()

    /// internal panel state
    @State internal var panelTransitionState: SlideOverTransitionState = .collapsed

    /// transition percent, whem set to max value the panel is expaned
    /// range [0,1]
    @State internal var panelTransitionPercent: Double? = 0.0

    /// threshold if exceeded the transition state is toggled
    private let horizontalGestureThreshold: Double = 0.225

    public var body: some View {
        GeometryReader { proxy in
            SlideOverPanel(
                content: content,
                tokens: tokens,
                transitionState: $panelTransitionState,
                percentTransition: $panelTransitionPercent)
                .backgroundOpactiy(backgroundLayerOpacity)
                .direction(slideOutDirection)
                .width(sizeInCurrentOrientation(proxy).width)
                .performOnBackgroundTap {
                    state.isExpanded = false
                }
                .onReceive(state.$isExpanded, perform: { value in
                    guard let value = value, state.translation == nil else {
                        return
                    }

                    withAnimation(defaultAnimation()) {
                        if value {
                            panelTransitionState = .expanded
                        } else {
                            panelTransitionState = .collapsed
                        }
                    }
                    panelTransitionPercent = nil
                })
                .onDisappear {
                    state.isExpanded = false
                }
                .gesture(dragGesture(screenWidth: sizeInCurrentOrientation(proxy).width))
                .onReceive(state.$translation) { value in
                    if let translation = value {
                        switch translation.state {
                        case .ended:
                            endTransition()
                        default:
                            let maxOffset = sizeInCurrentOrientation(proxy).width
                            let velocity = translation.point.x
                            updateTransition(Double(abs (velocity / maxOffset)), isAnimated: true)
                        }
                    }
                }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // When environment values are available through the view hierarchy:
            //  - If we get a non-default theme through the environment values,
            //    we use to override the theme from this view and its hierarchy.
            //  - Otherwise we just refresh the tokens to reflect the theme
            //    associated with the window that this View belongs to.
            if theme == ThemeKey.defaultValue {
                self.tokens.updateForCurrentTheme()
            } else {
                self.tokens.theme = theme
            }
        }
    }

    private func defaultAnimation() -> Animation {
        return Animation.easeInOut(duration: state.animationDuration)
    }

    private var backgroundLayerOpacity: Double {
        return Double(state.backgroundDimmed ? tokens.backgroundDimmedOpacity : tokens.backgroundClearOpacity)
    }

    private var slideOutDirection: SlideOverDirection {
        return state.presentationDirection == .left ? .left : .right
    }

    private func dragGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let velocity = value.translation.width
                updateTransition(Double(abs (velocity / screenWidth)), isAnimated: true, inverse: true)
            }
            .onEnded { _ in
                endTransition(inverse: true)
            }
    }

    private func updateTransition(_ percent: Double, isAnimated: Bool = false, inverse: Bool = false) {
        panelTransitionState = .inTransisiton
        if percent > 0 && percent < 1 {
            withAnimation(isAnimated ? defaultAnimation() : .none) {
                panelTransitionPercent = inverse ? 1 - percent : percent
            }
        }
    }

    private func endTransition(inverse: Bool = false) {
        guard let percent = panelTransitionPercent else {
            return
        }
        let snapPercent = inverse ? 1 - percent : percent
        let snapThreshold = inverse ? horizontalGestureThreshold : 1 - horizontalGestureThreshold
        if snapPercent < snapThreshold {
            state.isExpanded = true
        } else {
            state.isExpanded = false
        }
    }

    /// Custom modifier for adding a callback placeholder when drawer's state is changed
    /// - Parameter `didChangeState`: closure executed with drawer is expanded or collapsed
    /// - Returns: `Drawer`
    func didChangeState(_ didChangeState: @escaping () -> Void) -> Drawer {
        let drawerState = state
        drawerState.onStateChange = didChangeState
        return Drawer(content: content,
                      state: drawerState,
                      tokens: tokens)
    }

    private func sizeInCurrentOrientation(_ proxy: GeometryProxy) -> CGSize {
        if proxy.size.width < proxy.size.height {
            return CGSize(width: proxy.size.width, height: proxy.size.height)
        } else {
            return CGSize(width: proxy.size.height, height: proxy.size.width)
        }
    }
}

// MARK: - Previews

struct DrawerContent: View {
    var body: some View {
        ZStack {
            Color.red
            Text("Tap outside to collapse.")
        }
    }
}

struct DrawerPreview: View {
    var drawer = Drawer(content: DrawerContent())
    var body: some View {
        ZStack {
            NavigationView {
                EmptyView()
                    .navigationBarTitle(Text("Drawer Background"))
                    .navigationBarItems(leading: Button(action: {
                        drawer.state.isExpanded?.toggle()
                    }, label: {
                        Image(systemName: "sidebar.left")
                    })).background(Color.blue)
            }
            drawer
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        DrawerPreview()
    }
}
#endif
