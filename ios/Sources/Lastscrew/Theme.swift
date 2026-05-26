import SwiftUI

enum Theme {
    // Forged palette — see docs/brand/BRAND.md
    static let gunmetal    = Color(red: 0.086, green: 0.094, blue: 0.110)  // #16181C
    static let void        = Color(red: 0.031, green: 0.031, blue: 0.039)  // #08080A
    static let iron        = Color(red: 0.137, green: 0.149, blue: 0.169)  // #23262B
    static let steel       = Color(red: 0.204, green: 0.220, blue: 0.247)  // #34383F
    static let chrome      = Color(red: 0.910, green: 0.925, blue: 0.945)  // #E8ECF1
    static let chromeDim   = Color(red: 0.627, green: 0.651, blue: 0.690)  // #A0A6B0
    static let chromeFaint = Color(red: 0.420, green: 0.439, blue: 0.475)  // #6B7079
    static let molten      = Color(red: 1.000, green: 0.353, blue: 0.122)  // #FF5A1F
    static let moltenDeep  = Color(red: 0.722, green: 0.118, blue: 0.000)  // #B81E00
    static let amber       = Color(red: 1.000, green: 0.761, blue: 0.302)  // #FFC24D
    static let acid        = Color(red: 0.659, green: 1.000, blue: 0.208)  // #A8FF35
    static let blood       = Color(red: 0.878, green: 0.098, blue: 0.200)  // #E01933

    // Semantic aliases
    static let bg          = gunmetal
    static let surface     = iron
    static let surfaceRaised = Color(red: 0.176, green: 0.188, blue: 0.212)
    static let border      = steel
    static let text        = chrome
    static let textMuted   = chromeDim
    static let textFaint   = chromeFaint
    static let accent      = molten
    static let money       = acid
    static let danger      = blood
    static let warning     = amber

    // Type
    static let titleFont    = Font.system(size: 28, weight: .heavy, design: .default)
    static let headingFont  = Font.system(size: 20, weight: .semibold, design: .default)
    static let bodyFont     = Font.system(size: 16, weight: .regular, design: .default)
    // Money + figures: monospaced "gauge" feel (Share Tech Mono substitute on system fonts)
    static let bigMoneyFont = Font.system(size: 44, weight: .heavy, design: .monospaced)
    static let moneyFont    = Font.system(size: 22, weight: .bold,  design: .monospaced)
    static let monoFont     = Font.system(size: 14, weight: .semibold, design: .monospaced)

    // The forged gradient — used for every primary action
    static let earnGradient = LinearGradient(
        colors: [amber, molten, moltenDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Subtle heat behind hero numbers / accepted states
    static let heatHalo = RadialGradient(
        colors: [molten.opacity(0.35), molten.opacity(0.0)],
        center: .center, startRadius: 4, endRadius: 220
    )
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
