// AI Wrapper SwiftUI
// Created by Adam Lyttle on 7/9/2024

// Make cool stuff and share your build with me:

//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import SwiftUI
import AVFoundation
import Vision

struct LoadingView: View {
    @State private var leafOffset: CGFloat = UIScreen.main.bounds.height
    @Binding var isLoading: Bool
    
    var body: some View {
        ZStack {
            // Green background
            Color.green.edgesIgnoringSafeArea(.all)
            
            // Animated leaf icon
            Image(systemName: "leaf.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 5)
                .offset(y: leafOffset)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.8)) {
                        leafOffset = 0
                    }
                }
                .onChange(of: isLoading) { newValue in
                    if !newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            leafOffset = -UIScreen.main.bounds.height
                        }
                    }
                }
        }
    }
}

struct ContentView: View {
    @State private var chat: ChatModel?
    @State private var showChatSheet: Bool = false
    @State private var cameraIsActive: Bool = false
    @State private var showHistory: Bool = false
    @State private var showLanding: Bool = true
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                LoadingView(isLoading: $isLoading)
            } else {
                if showLanding {
                    LandingView(showLanding: $showLanding)
                } else {
                    CameraView(isActive: $cameraIsActive, onCaptureImage: { image in
                        //initialise the chat module first
                        chat = ChatModel()
                        
                        //wait a moment and then send the first prompt (what is this?)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if chat!.messages.count == 0 {
                                chat!.sendMessage(message: "Is this histamine friendly?", image: image)
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            cameraIsActive = false
                        }
                        
                        showChatSheet = true
                        
                    }, showHistory: $showHistory)
                    .sheet(isPresented: $showHistory) {
                        HistoryView(isPresented: $showHistory)
                    }
                    .sheet(item: $chat, onDismiss: {
                        withAnimation {
                            cameraIsActive = true
                        }
                    }) { chat in
                        NavigationView {
                            ChatView(isPresented: $showChatSheet, chat: chat)
                        }
                        .accentColor(.green)
                    }
                    .onChange(of: showChatSheet) { newValue in
                        if !newValue {
                            self.chat = nil
                        }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
        .onAppear {
            // Simulate loading time
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    }
}