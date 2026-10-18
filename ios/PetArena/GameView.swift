import SwiftUI
import UIKit
import WebKit

/// Full-screen web view that runs the bundled Pet Arena game.
struct GameView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: BundleSchemeHandler.scheme)
        // Persistent store so localStorage (trophies, coins, deck) survives app restarts.
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        let background = UIColor(named: "LaunchBackground")
        webView.isOpaque = false
        webView.backgroundColor = background
        webView.scrollView.backgroundColor = background
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        // Let the page handle safe areas itself via env(safe-area-inset-*).
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.delegate = context.coordinator
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        webView.load(URLRequest(url: BundleSchemeHandler.startURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        // Disable pinch-to-zoom; WKWebView ignores user-scalable=no.
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            nil
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            if url.scheme == BundleSchemeHandler.scheme || url.scheme == "about" {
                decisionHandler(.allow)
            } else {
                // Any outside link opens in Safari instead of replacing the game.
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        // iOS may kill the web content process in the background; bring the game back.
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.load(URLRequest(url: BundleSchemeHandler.startURL))
        }
    }
}

/// Serves the game from the app bundle under petarena://game/ so it works offline
/// and gets a stable origin for localStorage.
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "petarena"
    static let startURL = URL(string: "\(scheme)://game/index.html")!

    private static let gameFile = "Pet Arena (1)"
    /// Bundled copies of the Google Fonts the game uses, keyed by font family.
    private static let fonts = [
        ("Lilita One", "LilitaOne-Regular.ttf"),
        ("Creepster", "Creepster-Regular.ttf"),
    ]

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, let resource = Self.resource(for: url.path) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": resource.mimeType, "Content-Length": String(resource.data.count)]
        )!
        task.didReceive(response)
        task.didReceive(resource.data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    private static func resource(for path: String) -> (data: Data, mimeType: String)? {
        switch path {
        case "/", "/index.html":
            guard let url = Bundle.main.url(forResource: gameFile, withExtension: "html"),
                  let html = try? String(contentsOf: url, encoding: .utf8)
            else { return nil }
            return (Data(offlineFont(html).utf8), "text/html; charset=utf-8")
        default:
            let name = String(path.dropFirst())
            guard fonts.contains(where: { $0.1 == name }),
                  let url = Bundle.main.url(forResource: name, withExtension: nil),
                  let data = try? Data(contentsOf: url)
            else { return nil }
            return (data, "font/ttf")
        }
    }

    /// Swaps the Google Fonts stylesheet for the bundled font files.
    private static func offlineFont(_ html: String) -> String {
        let faces = fonts.map { family, file in
            "@font-face{font-family:'\(family)';src:url('\(file)') format('truetype');font-display:swap}"
        }
        let localFont = "<style>\(faces.joined())</style>"
        return html.replacingOccurrences(
            of: #"<link[^>]*fonts\.googleapis\.com[^>]*>"#,
            with: localFont,
            options: .regularExpression
        )
    }
}
