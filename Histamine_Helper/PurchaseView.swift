// PurchaseView SwiftUI
// Created by Adam Lyttle on 7/18/2024

// Make cool stuff and share your build with me:

//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import SwiftUI

struct PurchaseView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Text("Unlock Premium Access")
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)
            
            // Add your purchase options and UI here
            
            Button("Close") {
                isPresented = false
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}