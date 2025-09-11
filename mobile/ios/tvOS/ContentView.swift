import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Mar-OS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Hello from tvOS!")
                .font(.title)
            
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