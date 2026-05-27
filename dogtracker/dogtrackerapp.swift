import SwiftUI

@main
struct DogTrackerApp: App {
    @StateObject private var viewModel = DogTrackerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
