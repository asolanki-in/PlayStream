//
//  ContentView.swift
//  PlayScreen
//
//  Created by Anil Solanki on 09/11/24.
//

import SwiftUI
import ReplayKit

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Screen Broadcast")
                .font(.largeTitle)
                .padding()

            BroadcastPicker()
        }
    }
}

struct BroadcastPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        picker.preferredExtension = "com.ibridge.PlayScreen.PlayExtension"
        picker.showsMicrophoneButton = false
        return picker
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}


#Preview {
    ContentView()
}
