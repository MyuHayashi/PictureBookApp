import Foundation
import CoreData

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var books: [Book] = []
    @Published var favoriteBooks: [Book] = []
    
    private let persistenceController = PersistenceController.shared
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    private init() {
        fetchBooks()
        createSampleDataIfNeeded()
    }
    
    // MARK: - Fetch
    func fetchBooks() {
        let request: NSFetchRequest<Book> = Book.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            books = try viewContext.fetch(request)
            fetchFavoriteBooks()
        } catch {
            print("Error fetching books: \(error)")
        }
    }
    
    func fetchFavoriteBooks() {
        let request: NSFetchRequest<Book> = Book.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            favoriteBooks = try viewContext.fetch(request)
        } catch {
            print("Error fetching favorite books: \(error)")
        }
    }
    
    // MARK: - Create
    func createBook(id: String, title: String, coverImageName: String) {
        let newBook = Book(context: viewContext)
        newBook.id = id
        newBook.title = title
        newBook.coverImageName = coverImageName
        newBook.isFavorite = false
        newBook.readCount = 0
        newBook.createdAt = Date()
        
        save()
    }
    
    // MARK: - Update
    func toggleFavorite(book: Book) {
        book.isFavorite.toggle()
        save()
        fetchFavoriteBooks()
    }
    
    func incrementReadCount(book: Book) {
        book.readCount += 1
        book.lastReadDate = Date()
        save()
    }
    
    // MARK: - Save
    private func save() {
        do {
            try viewContext.save()
            fetchBooks()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // MARK: - Sample Data
    private func createSampleDataIfNeeded() {
        // 既にデータがある場合は作成しない
        if !books.isEmpty { return }
        
        let sampleBooks = [
            ("book_001", "浦島太郎", "urashima"),
            ("book_002", "桃太郎", "momotaro"),
            ("book_003", "かぐや姫", "kaguya"),
            ("book_004", "鶴の恩返し", "tsuru"),
            ("book_005", "一寸法師", "issunboushi"),
            ("book_006", "花咲かじいさん", "hanasaka")
        ]
        
        for (id, title, imageName) in sampleBooks {
            createBook(id: id, title: title, coverImageName: imageName)
        }
    }
}
