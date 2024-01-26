//
//  PreferencesView.swift
//  StatusBarRunner
//
//  Created by ou on 12/24/23.
//
import SwiftUI
import LaunchAtLogin
import WebKit
import Cocoa

struct PreferencesView: View {
    @State private var markdownText: String = ""
    @Binding var isPresented: Bool

    
    
    struct MarkdownWebView: NSViewRepresentable {
        let htmlContent: String

        func makeNSView(context: Context) -> WKWebView {
            return WKWebView()
        }

        func updateNSView(_ nsView: WKWebView, context: Context) {
            nsView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
    struct WebView: NSViewRepresentable {
        var url: URL

        func makeNSView(context: Context) -> WKWebView {
            return WKWebView()
        }

        func updateNSView(_ nsView: WKWebView, context: Context) {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                LaunchAtLogin.Toggle {
                    Text("Launch at login")
                }.buttonStyle(PlainButtonStyle())
                .padding() .padding(.leading, 15)
                Spacer()
                Button(action: {
                    // Open github.com in the default browser
                    NSWorkspace.shared.open(URL(string: "https://github.com")!)
                }) {
                    HStack {
                        Image(systemName: "house")
                            .font(.system(size: 16)) // Set the font size to 20px
                    }
                }.buttonStyle(PlainButtonStyle()) .padding(.trailing, 15)
                
                Button(action: {
                    isPresented = false  // 关闭视图
                }) {
                    HStack {
                        Image(systemName: "escape")
                            .font(.system(size: 15)) // Set the font size to 20px
                    }
                }.buttonStyle(PlainButtonStyle()) .padding(.trailing, 15)
            }
            WebView(url: URL(string: "https://m.baidu.com")!)
                        .frame(width: 400, height: 400) // 设置固定的高度和宽度
                }
//            MarkdownWebView(htmlContent: loadMarkdown())
//                            .frame(width: 400, height: 400) // 设置固定的高度和宽度
//        }
    }
//    func loadMarkdown() -> String {
//            guard let filePath = Bundle.main.path(forResource: "Readme", ofType: "html"),
//                  let markdownText = try? String(contentsOfFile: filePath) else {
//                return "Unable to load Readme.html"
//            }
//            return markdownText
//        }
}
