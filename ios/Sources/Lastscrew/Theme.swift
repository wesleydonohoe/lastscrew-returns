import SwiftUI

enum Theme {
    static let purple = Color(red: 0.482, green: 0.094, blue: 0.624)        // #7B189F
    static let purpleDeep = Color(red: 0.36, green: 0.05, blue: 0.50)
    static let green = Color(red: 0.055, green: 0.624, blue: 0.431)         // #0E9F6E
    static let red = Color(red: 0.765, green: 0.176, blue: 0.176)           // #C32D2D
    static let bg = Color(red: 0.98, green: 0.98, blue: 0.98)               // #FAFAFA
    static let text = Color(red: 0.10, green: 0.10, blue: 0.10)             // #1A1A1A
    static let muted = Color(white: 0.55)
    static let cardStroke = Color(white: 0.92)

    static let titleFont = Font.system(size: 28, weight: .bold, design: .default)
    static let headingFont = Font.system(size: 20, weight: .semibold, design: .default)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let bigMoneyFont = Font.system(size: 44, weight: .bold, design: .rounded)
    static let moneyFont = Font.system(size: 22, weight: .semibold, design: .rounded)

    static let earnGradient = LinearGradient(
        colors: [purple, Color(red: 0.65, green: 0.35, blue: 0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
