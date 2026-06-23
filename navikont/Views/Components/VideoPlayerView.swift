import SwiftUI
import AVKit
import WebKit

struct VideoPlayerView: View {
    @Environment(\.colorScheme) var colorScheme
    let urlString: String
    
    var body: some View {
        if isYouTube(url: urlString) {
            YouTubePlayerView(youtubeID: extractYouTubeID(from: urlString))
                .frame(height: 220)
                .cornerRadius(12)
        } else if let url = URL(string: urlString) {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(height: 220)
                .cornerRadius(12)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 220)
                .cornerRadius(12)
                .overlay(Text("Geçersiz Video").foregroundColor(.white))
        }
    }
    
    private func isYouTube(url: String) -> Bool {
        return url.contains("youtube.com") || url.contains("youtu.be")
    }
    
    private func extractYouTubeID(from url: String) -> String {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return "" }
        let range = NSRange(location: 0, length: url.utf16.count)
        if let match = regex.firstMatch(in: url, options: [], range: range) {
            return (url as NSString).substring(with: match.range)
        }
        return ""
    }
}

struct YouTubePlayerView: UIViewRepresentable {
    let youtubeID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(youtubeID)?playsinline=1") else { return }
        uiView.load(URLRequest(url: url))
    }
}
