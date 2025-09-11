import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Mar-OS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(getGreeting())
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
    
    func getGreeting() -> String {
        // Placeholder for KMP framework integration
        // TODO: Replace with actual Greeting().greet() call from KMP framework
        #if os(iOS)
        return "Hello, iOS! Welcome to Mar-OS!"
        #elseif os(tvOS)
        return "Hello, tvOS! Welcome to Mar-OS!"
        #elseif os(watchOS)
        return "Hello, watchOS! Welcome to Mar-OS!"
        #else
        return "Hello, Apple! Welcome to Mar-OS!"
        #endif
    }
}

#Preview {
    ContentView()
}