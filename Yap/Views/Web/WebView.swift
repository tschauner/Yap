//
//  WebView.swift
//  Yap
//
//  Created by Philipp Tschauner on 18.03.26.
//

import SwiftUI
import WebKit

struct WebURL: Identifiable {
    let id = UUID().uuidString
    let url: URL
}

struct WebView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let url: URL
    
    var body: some View {
        NavigationStack {
            WebViewKit(url: url, isDarkMode: colorScheme == .dark)
                .ignoresSafeArea(edges: .bottom)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Text(L10n.Common.done)
                            .button {
                                dismiss()
                            }
                    }
                }
        }
    }
}

struct WebViewKit: UIViewRepresentable {
    let url: URL
    let isDarkMode: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // Baue die URL mit Query-Parameter
        let baseUrlString = url.absoluteString
        let themeParam = isDarkMode ? "dark" : "light"
        let urlString = "\(baseUrlString)?theme=\(themeParam)"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Bei jeder Änderung den JS-Aufruf
        let theme = isDarkMode ? "dark" : "light"
        let script = "switchTheme('\(theme)')"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}

#Preview {
    WebView(url: .init(string: "www.google.com")!)
}
