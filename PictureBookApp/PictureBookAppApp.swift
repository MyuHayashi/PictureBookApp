//
//  PictureBookAppApp.swift
//  PictureBookApp
//
//  Created by MYU HAYASHI on 2025/07/02.
//

import SwiftUI

@main
struct PictureBookAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
