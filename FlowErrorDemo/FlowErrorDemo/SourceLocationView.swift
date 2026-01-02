import Foundation
import SwiftUI

struct SourceLocation {
    var file: StaticString
    var line: Int
    
    init(file: StaticString = #fileID, line: Int = #line) {
        self.file = file
        self.line = line
    }
}

extension View {
    func sourceLocation(sourceLocation: SourceLocation) -> some View {
        modifier(SourceLocationModifier(sourceLocation: sourceLocation))
    }
}

/// A view that displays the name of the file it is used into,
/// and a "Copy Path" button.
///
/// The "Copy Path" button does not work in previews.
private struct SourceLocationView: View {
    let fileName: String
    @State var copied = false
    
    init(_ sourceLocation: SourceLocation) {
        fileName = ("\(sourceLocation.file)" as NSString).lastPathComponent + ":\(sourceLocation.line)"
    }
    
    var body: some View {
        VStack {
            Text(fileName)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button {
                UIPasteboard.general.string = fileName
                copied = true
            } label: {
                Text(copied ? "Copied!" : "Copy Path")
            }
            .disabled(copied)
        }
        .font(.callout)
        .task(id: copied) {
            if copied {
                try? await Task.sleep(for: .seconds(1))
                copied = false
            }
        }
    }
}

private struct SourceLocationModifier: ViewModifier {
    var sourceLocation: SourceLocation
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxHeight: .infinity)
            
            SourceLocationView(sourceLocation)
                .frame(maxWidth: .infinity)
                .padding([.top, .horizontal])
                .background(.regularMaterial)
        }
        
    }
}

struct SourceLocationView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
            .sourceLocation(sourceLocation: SourceLocation())
    }
}
