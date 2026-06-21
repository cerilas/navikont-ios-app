import SwiftUI
import WebKit

struct EmbeddedPDFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // Make the background transparent/clean
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        // Load the PDF url
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // If needed, reload the request when url changes
        if uiView.url?.absoluteString != url.absoluteString {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}
