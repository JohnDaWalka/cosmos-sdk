import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Mar-OS")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Hello from watchOS!")
                .font(.caption)
            
            Text("KMP soon...")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}