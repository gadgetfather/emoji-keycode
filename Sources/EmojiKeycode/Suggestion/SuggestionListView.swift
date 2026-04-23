import SwiftUI

struct SuggestionListView: View {
    let matches: [EmojiMatch]
    let selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(matches.enumerated()), id: \.offset) { idx, match in
                HStack(spacing: 10) {
                    Text(match.emoji)
                        .font(.system(size: 16))
                        .frame(width: 22, alignment: .center)
                    Text(":\(match.shortcode):")
                        .font(.system(size: 12, weight: idx == selectedIndex ? .semibold : .regular, design: .monospaced))
                        .foregroundColor(idx == selectedIndex ? .white : .primary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    idx == selectedIndex
                        ? AnyShapeStyle(Color.accentColor)
                        : AnyShapeStyle(Color.clear)
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
        )
        .frame(width: 260)
    }
}
