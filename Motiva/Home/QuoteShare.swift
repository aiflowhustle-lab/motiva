import SwiftUI
import UIKit

/// Fixed classic-black layout for sharing a quote as an image.
struct QuoteShareCard: View {
    let quote: String

    var body: some View {
        ZStack {
            Color(hex: 0x131313)
            VStack(spacing: 0) {
                Spacer(minLength: 80)
                Text(quote)
                    .font(.custom("BricolageGrotesque-SemiBold", size: 44))
                    .foregroundStyle(Color(hex: 0xFCFCFC))
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 72)
                Spacer(minLength: 80)
                Image("MotivaLogoTransparent")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .padding(.bottom, 72)
            }
        }
        .frame(width: 1080, height: 1080)
    }
}

enum QuoteShareRenderer {
    @MainActor
    static func image(for quote: String) -> UIImage? {
        let renderer = ImageRenderer(content: QuoteShareCard(quote: quote))
        renderer.scale = 1
        return renderer.uiImage
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
