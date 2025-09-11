import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Mar-OS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Hello from iOS!")
                .font(.title2)
            
            Text("KMP Integration coming soon...")
                .font(.body)
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