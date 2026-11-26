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
            }
            .navigationTitle("ReadMeApp")
        }
    }
}

#Preview {
    ContentView()
}
