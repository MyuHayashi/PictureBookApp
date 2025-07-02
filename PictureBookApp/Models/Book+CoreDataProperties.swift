import Foundation
import CoreData

extension Book {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }
    
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var coverImageName: String
    @NSManaged public var isFavorite: Bool
    @NSManaged public var readCount: Int32
    @NSManaged public var lastReadDate: Date?
    @NSManaged public var createdAt: Date
}

// MARK: - Identifiable
extension Book: Identifiable {
    
}
