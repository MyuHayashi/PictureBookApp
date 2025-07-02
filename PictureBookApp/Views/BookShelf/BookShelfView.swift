import SwiftUI

struct BookShelfView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showFavoritesOnly = false
    
    var displayedBooks: [Book] {
        showFavoritesOnly ? dataManager.favoriteBooks : dataManager.books
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // フィルターセクション
                    HStack {
                        Text(showFavoritesOnly ? "お気に入りの絵本" : "すべての絵本")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showFavoritesOnly.toggle()
                            }
                        }) {
                            Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 絵本グリッド
                    if displayedBooks.isEmpty {
                        Text(showFavoritesOnly ? "お気に入りの絵本がありません" : "絵本がありません")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(displayedBooks) { book in
                                BookItemView(book: book)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("えほんのほんだな")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// 絵本アイテムのビュー
struct BookItemView: View {
    let book: Book
    @StateObject private var dataManager = DataManager.shared
    @State private var showBookViewer = false  // 追加
    
    var body: some View {
        VStack(spacing: 10) {
            // 絵本のカバー
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "book.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            if book.readCount > 0 {
                                Text("読了: \(book.readCount)回")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(5)
                            }
                        }
                    )
                
                // お気に入りボタン
                Button(action: {
                    withAnimation(.spring()) {
                        dataManager.toggleFavorite(book: book)
                    }
                }) {
                    Image(systemName: book.isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.title2)
                        .padding(10)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(8)
            }
            
            // タイトル
            Text(book.title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // 読むボタン（変更）
            Button(action: {
                showBookViewer = true
            }) {
                Text("読む")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(5)
            }
        }
        .padding(.bottom, 5)
        .fullScreenCover(isPresented: $showBookViewer) {  // 追加
            BookViewerView(book: book)
        }
    }
}

#Preview {
    BookShelfView()
}
