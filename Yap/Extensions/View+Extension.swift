//
//  View+Extension.swift
//  Yap
//
//  Created by Philipp Tschauner on 03.03.26.
//

import SwiftUI

extension View {
    func button(role: ButtonRole? = nil, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        modifier(ButtonWrapperModifier(buttonRole: role, isEnabled: isEnabled, action: action))
    }
    
    func orangeShadow(show: Bool = true) -> some View {
        shadow(color: Color.orange.opacity(show ? 0.3 : 0), radius: 20)
    }

    func hapticFeedback(trigger: any Equatable, intensity: Double = 0.65) -> some View {
        modifier(HapticFeedbackModifier(trigger: trigger, intensity: intensity))
    }
    
    func errorFeedback(trigger: any Equatable) -> some View {
        modifier(ErrorFeedbackModifier(trigger: trigger))
    }
    
    func showLoading(show: Bool, opacity: Double = 0.5) -> some View {
        modifier(ShowLoadingModifier(showLoading: show, opacity: opacity))
    }
    
    func circleGradientOutline(lineWidth: CGFloat = 2) -> some View {
        modifier(CircleGradientOutlineModifier(lineWidth: lineWidth))
    }
    
    func gradientOutline(cornerRadius: CGFloat = 20, lineWidth: CGFloat = 2) -> some View {
        modifier(RoundedGradientOutlineModifier(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
    
    func gradient(cornerRadius: CGFloat = 20) -> some View {
        modifier(RoundedGradientModifier(cornerRadius: cornerRadius))
    }
    
    func roundedOutline(lineWidth: CGFloat = 1.5, cornerRadius: CGFloat, color: Color = Color(.systemGray6)) -> some View {
        modifier(RoundedOutlineModifier(cornerRadius: cornerRadius, lineWidth: lineWidth, color: color))
    }
    
    func outline(lineWidth: CGFloat = 1.5, color: Color = Color.primary) -> some View {
        modifier(BorderModifier(lineWidth: lineWidth, color: color))
    }
    
    func capsule(color: Color = .white) -> some View {
        modifier(CapsuleModifier(color: color))
    }
    
    func scaleOnTap(_ scale: CGFloat = 0.95) -> some View {
        buttonStyle(PressableButtonStyle(scale: scale))
    }
    
    func pressed(action: @escaping () -> Void, scale: CGFloat = 0.95) -> some View {
        modifier(PressedButtonViewModifier(action: action, scale: scale))
    }
    
    func isLoading(_ value: Bool) -> some View {
        environment(\.isLoading, value)
    }
    
    func skeleton() -> some View {
        modifier(SkeletonModifier())
    }
    
    func pinchToZoom() -> some View {
        modifier(MagnifierModifier())
    }
}

struct MagnifierModifier: ViewModifier {
    @State private var zoom: CGFloat = 1.0
    @State private var anchor: UnitPoint = .center
    
    func body(content: Content) -> some View {
        content
            .zIndex(zoom > 1 ? 1 : 0)
            .scaleEffect(zoom, anchor: anchor)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        anchor = UnitPoint(
                            x: value.startLocation.x / UIScreen.main.bounds.width,
                            y: value.startLocation.y / 400
                        )
                        zoom = value.magnification
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            zoom = 1.0
                        }
                    },
                including: .gesture
            )
    }
}

struct CapsuleModifier: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .background(color)
            .clipShape(Capsule())
    }
}

struct RoundedOutlineModifier: ViewModifier {
    var cornerRadius: CGFloat
    var lineWidth: CGFloat
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

struct RoundedGradientOutlineModifier: ViewModifier {
    var cornerRadius: CGFloat
    var lineWidth: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Gradient(colors: [Color.blue, .pink, .purple]), lineWidth: lineWidth)
            )
    }
}

struct CircleGradientOutlineModifier: ViewModifier {
    var lineWidth: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(Gradient(colors: [Color.blue, .pink, .purple]), lineWidth: lineWidth)
            )
    }
}

struct RoundedGradientModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                Gradient(colors: [Color.blue, .pink, .purple])
                
            )
            .cornerRadius(cornerRadius)
    }
}

struct ShowLoadingModifier: ViewModifier {
    let showLoading: Bool
    @State var opacity: Double
    
    func body(content: Content) -> some View {
        if showLoading {
            content
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        opacity = 1
                    }
                }
        } else {
            content
        }
    }
}

struct HapticFeedbackModifier: ViewModifier {
    @AppStorage("hapticFeedbackEnabled") var hapticFeedbackEnabled: Bool = true
    let trigger: any Equatable
    let intensity: Double
    
    func body(content: Content) -> some View {
        AnyView(content
            .sensoryFeedback( .impact(flexibility: .soft, intensity: hapticFeedbackEnabled ? intensity : 0), trigger: trigger))
    }
}

struct ErrorFeedbackModifier: ViewModifier {
    let trigger: any Equatable
    var impact: SensoryFeedback = .warning
    
    func body(content: Content) -> some View {
        AnyView(content
            .sensoryFeedback(impact, trigger: trigger) { _, newValue in
                (newValue as? Bool) == true
            }
        )
    }
}

struct ButtonWrapperModifier: ViewModifier {
    var buttonRole: ButtonRole?
    var isEnabled: Bool = true
    var action: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            Button(role: buttonRole) {
                action()
            } label: {
                content
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

struct BorderModifier: ViewModifier {
    var lineWidth: CGFloat
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

struct BackgroundModifier: ViewModifier {
    let light: Color
    let dark: Color
    let darker: Double
    
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [light, dark.darker(by: darker)], startPoint: .topTrailing, endPoint: .bottom)
            )
    }
}

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.8

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeInOut(duration: 0.4), value: configuration.isPressed)
    }
}

struct PressedButtonViewModifier: ViewModifier {
    var action: () -> Void
    var scale: CGFloat
    
    func body(content: Content) -> some View {
        Button {
            action()
        } label: {
            content
        }
        .scaleOnTap(scale)
    }
}

struct IsLoading: EnvironmentKey {
    static var defaultValue: Bool = false
}

public extension EnvironmentValues {
    var isLoading: Bool {
        get { self[IsLoading.self] }
        set { self[IsLoading.self] = newValue }
    }
}

struct SkeletonModifier: ViewModifier {
    @Environment(\.isLoading) var isLoading
    @State private var animationStarted = false
    
    private let skeletonAnimation: Animation = {
        let animation = Animation.easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        return animation
    }()
    
    func body(content: Content) -> some View {
        if isLoading {
            content
                //.redacted(reason:  .placeholder)
                .opacity(animationStarted ? 0.3 : 1)
                .accessibilityHidden(isLoading)
                .onAppear {
                    withAnimation(skeletonAnimation) {
                        animationStarted = true
                    }
                }
        } else {
            content
        }
    }
}

extension Color {
    /// Gibt eine dunklere Version der Farbe zurück.
    /// Percentage: 0 bis 100 – z. B. 30 bedeutet 30% dunkler.
    func darker(by percentage: Double = 70.0) -> Color {
        // Konvertiere die SwiftUI Color in UIColor
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newBrightness = max(brightness - CGFloat(percentage / 100), 0)
            let darkerUIColor = UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
            return Color(darkerUIColor)
        }
        return self
    }
}
