import SwiftUI

@main
struct LivenessExampleApp: App {
  var body: some Scene {
    WindowGroup {
      TabView {
        NavigationView { QuickStartView() }
          .navigationViewStyle(.stack)
          .tabItem { Label("Quick start", systemImage: "faceid") }
        NavigationView { BackendFlowView() }
          .navigationViewStyle(.stack)
          .tabItem { Label("Backend flow", systemImage: "network") }
      }
    }
  }
}
