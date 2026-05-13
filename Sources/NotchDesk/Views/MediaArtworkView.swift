import AppKit
import SwiftUI

struct MediaArtworkView<Placeholder: View>: View {
    let artworkURL: URL?
    let cornerRadius: CGFloat
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear(perform: loadImage)
        .onChange(of: artworkURL) { _, _ in
            loadImage()
        }
    }

    private func loadImage() {
        guard let artworkURL else {
            image = nil
            return
        }

        if artworkURL.isFileURL {
            image = NSImage(contentsOf: artworkURL)
            return
        }

        URLSession.shared.dataTask(with: artworkURL) { data, _, _ in
            let loadedImage = data.flatMap(NSImage.init(data:))
            DispatchQueue.main.async {
                if self.artworkURL == artworkURL {
                    self.image = loadedImage
                }
            }
        }.resume()
    }
}
