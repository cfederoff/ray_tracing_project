import SwiftUI

@main
struct ProjectApp: App {
    
    @StateObject private var gamescene = GameScene()
    
    var body: some Scene {
        
        WindowGroup {
            appView()
                .environmentObject(gamescene)
        }
    }
}
