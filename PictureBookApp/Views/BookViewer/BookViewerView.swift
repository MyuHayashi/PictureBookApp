import SwiftUI
import AVFoundation
import UIKit

// 読書モード
enum ReadingMode: String, CaseIterable {
    case silent = "音声なし"
    case audioManual = "音声あり（手動）"
    case audioAuto = "音声あり（自動）"
    
    var icon: String {
        switch self {
        case .silent: return "speaker.slash.fill"
        case .audioManual: return "speaker.wave.2.fill"
        case .audioAuto: return "play.circle.fill"
        }
    }
}

struct BookViewerView: View {
    let book: Book
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // ページ管理
    @State private var currentPage = 0
    @State private var totalPages = 5 // 仮のページ数
    
    // 読書モード
    @State private var readingMode: ReadingMode = .silent
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    
    // 音声再生（将来の実装用）
    @State private var isPlaying = false
    
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()
            
            // ページコンテンツ
            TabView(selection: $currentPage) {
                ForEach(0..<totalPages, id: \.self) { pageIndex in
                    PageContentView(
                        book: book,
                        pageNumber: pageIndex + 1,
                        totalPages: totalPages
                    )
                    .tag(pageIndex)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls.toggle()
                }
                resetControlsTimer()
            }
            
            // コントロールオーバーレイ
            if showControls {
                VStack {
                    // トップバー
                    TopControlBar(
                        book: book,
                        readingMode: $readingMode,
                        onClose: {
                            // 画面回転を解除
                            AppDelegate.orientationLock = .all
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                    
                    Spacer()
                    
                    // ボトムバー
                    BottomControlBar(
                        currentPage: $currentPage,
                        totalPages: totalPages,
                        readingMode: readingMode,
                        isPlaying: $isPlaying
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 読了回数を増やす
            dataManager.incrementReadCount(book: book)
            if !isLandscape {
                startControlsTimer()
            } else {
                showControls = false
            }
        }
        .onChange(of: isLandscape) { newValue in
            if newValue {
                // 横向きになったらコントロールを隠す
                showControls = false
                controlsTimer?.invalidate()
            } else {
                // 縦向きに戻ったらコントロールを表示してタイマー開始
                showControls = true
                startControlsTimer()
            }
        }
        .onDisappear {
            controlsTimer?.invalidate()
            // 画面回転を解除
            AppDelegate.orientationLock = .all
        }
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func resetControlsTimer() {
        if showControls {
            startControlsTimer()
        }
    }
}

// MARK: - ページコンテンツ
struct PageContentView: View {
    let book: Book
    let pageNumber: Int
    let totalPages: Int
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isLandscape: Bool {
        verticalSizeClass == .compact || horizontalSizeClass == .regular
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色（黒）
                Color.black.ignoresSafeArea()
                
                if isLandscape {
                    // 横向き：画像のみ全画面表示
                    imageContent
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    // 縦向き：16:9の画像 + テキスト
                    VStack(spacing: 0) {
                        // 16:9の画像エリア
                        imageContent
                            .frame(width: geometry.size.width, height: geometry.size.width * 9/16)
                            .clipped()
                        
                        // テキストエリア
                        VStack(spacing: 20) {
                            Text(getSampleText(for: pageNumber))
                                .font(.system(size: 18, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.top, 30)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var imageContent: some View {
        ZStack {
            // 実際の画像が入る場所（今はプレースホルダー）
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hue: Double(pageNumber) / Double(totalPages), saturation: 0.5, brightness: 0.8),
                            Color(hue: Double(pageNumber) / Double(totalPages), saturation: 0.3, brightness: 0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // プレースホルダーコンテンツ
            VStack(spacing: 20) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.5))
                Text("ページ \(pageNumber)")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
                
                if isLandscape {
                    // 横向きの時はテキストも画像内に表示
                    Text(getSampleText(for: pageNumber))
                        .font(.system(size: 24, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 60)
                        .padding(.top, 20)
                }
            }
        }
    }
    
    private func getSampleText(for page: Int) -> String {
        switch page {
        case 1:
            return "むかしむかし、あるところに\n\(book.title)がいました。"
        case 2:
            return "ある日のことです。\nとても不思議なことが起きました。"
        case 3:
            return "みんなでちからを合わせて\nがんばりました。"
        case 4:
            return "そして、ついに\n願いがかないました。"
        case 5:
            return "みんな幸せに暮らしました。\nおしまい。"
        default:
            return "ページ \(page) のテキスト"
        }
    }
}

// MARK: - トップコントロールバー
struct TopControlBar: View {
    let book: Book
    @Binding var readingMode: ReadingMode
    let onClose: () -> Void
    @State private var orientation = UIDeviceOrientation.portrait
    
    var body: some View {
        HStack {
            // 閉じるボタン
            Button(action: onClose) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // タイトル
            Text(book.title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
            
            Spacer()
            
            HStack(spacing: 15) {
                // 読書モード切り替え
                Menu {
                    ForEach(ReadingMode.allCases, id: \.self) { mode in
                        Button(action: {
                            withAnimation {
                                readingMode = mode
                            }
                        }) {
                            Label(
                                mode.rawValue,
                                systemImage: mode.icon
                            )
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: readingMode.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                // 画面回転ボタン
                Button(action: {
                    if orientation.isPortrait {
                        // 横向きに強制
                        AppDelegate.orientationLock = .landscape
                        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                    } else {
                        // 縦向きに強制
                        AppDelegate.orientationLock = .portrait
                        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    }
                    // 少し待ってから全方向を許可
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AppDelegate.orientationLock = .all
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 44, height: 44)
                        
                        // 基本的なアイコンを使用
                        Image(systemName: "viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
    }
}

// MARK: - ボトムコントロールバー
struct BottomControlBar: View {
    @Binding var currentPage: Int
    let totalPages: Int
    let readingMode: ReadingMode
    @Binding var isPlaying: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // 音声コントロール（音声ありモードの場合）
            if readingMode != .silent {
                HStack(spacing: 30) {
                    // 前のページ
                    Button(action: {
                        if currentPage > 0 {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .disabled(currentPage == 0)
                    
                    // 再生/一時停止
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    // 次のページ
                    Button(action: {
                        if currentPage < totalPages - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .disabled(currentPage == totalPages - 1)
                }
                .padding(.top, 10)
            }
            
            // ページインジケーター
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 10)
            
            // ページ番号
            Text("\(currentPage + 1) / \(totalPages)")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let book = Book(context: context)
    book.title = "サンプル絵本"
    book.id = "sample_001"
    book.coverImageName = "sample"
    book.isFavorite = false
    book.readCount = 0
    book.createdAt = Date()
    
    return BookViewerView(book: book)
}
