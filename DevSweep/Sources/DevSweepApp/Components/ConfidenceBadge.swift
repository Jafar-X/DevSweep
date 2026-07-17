import SwiftUI

struct ConfidenceBadge: View {
    let score: Int

    private var color: Color {
        switch score {
        case 80...100: .green
        case 60..<80:  .orange
        default:       .red
        }
    }

    private var label: String {
        switch score {
        case 80...100: "Safe"
        case 60..<80:  "Review"
        default:       "Keep"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(score)%")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}
