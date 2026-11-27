import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Alert") {
                    DocumentView()
                }
                NavigationLink("Error Presentation") {
                    NewsView()
                }
                NavigationLink("Unhandled Error") {
                    UnhandledErrorView()
                }
            }
            .navigationTitle("ReadMeApp")
        }
    }
}

#Preview {
    ContentView()
}
