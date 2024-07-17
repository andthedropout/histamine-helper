// AI Wrapper SwiftUI
// Created by Adam Lyttle on 7/9/2024

// Make cool stuff and share your build with me:

//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import SwiftUI
import Speech

struct MessageInputView: View {

    @Environment(\.colorScheme) var colorScheme

    @State var value: String = ""
    //@State private var showingSearchField: Bool = false //triggers when search textbox is to be displayed
    @FocusState private var isFocused: Bool
    @State var focusOnView: Bool = false
    
    @State private var hideSearchValue: Bool = false
    
    var onChange: ((String) -> Void)?
    
    var message: (String) -> Void
    
    @State var height: CGFloat = 30
    
    @State private var isRecording = false
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let audioEngine = AVAudioEngine()
    
    @State private var isAuthorized = false
    @State private var hasRequestedPermission = false

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    if !hasRequestedPermission {
                        requestSpeechAuthorization()
                    } else if isAuthorized {
                        isRecording ? stopRecording() : startRecording()
                    }
                }) {
                    Image(systemName: isRecording ? "stop.circle" : "mic")
                }
                .accentColor(colorScheme == .dark ? .white : .black)
                
                if(!hideSearchValue) {
                    ZStack (alignment: .leading) {
                        TextEditor(text: $value)
                            .frame(height: height)
                            .focused($isFocused)
                            .onAppear {
                                if focusOnView {
                                    isFocused = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        focusOnView = false
                                    }
                                }
                            }
                            .onChange(of: value) { newValue in
                                if newValue.last == "\n" {
                                    value = String(newValue.dropLast())
                                    sendMessage()
                                }
                            }
                        
                        Text(value.isEmpty ? "Enter message..." : value)
                            .opacity(value.isEmpty ? 0.5 : 0)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 5)
                            .padding(.top, 4)
                            .background {
                                GeometryReader { proxy in
                                    Rectangle()
                                        .foregroundColor(.clear)
                                        .onChange(of: value) { _ in
                                            height = min(120, max(30, proxy.size.height))
                                        }
                                }
                            }
                            .onTapGesture {
                                isFocused = true
                            }
                    }
                    .offset(y: -3)
                }
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane")
                }
                .accentColor(colorScheme == .dark ? .white : .black)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .accentColor(.black)
    }
    
    func sendMessage() {
        if !value.isEmpty {
            message(value)
            value = ""
        }
    }
    
    private func startRecording() {
        guard isAuthorized else {
            print("Speech recognition not authorized")
            return
        }
        guard let recognitionRequest = try? SFSpeechAudioBufferRecognitionRequest() else { return }

        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioEngine.inputNode.outputFormat(forBus: 0)) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.value = result.bestTranscription.formattedString
                }
            }
        }

        isRecording = true
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.isAuthorized = authStatus == .authorized
                self.hasRequestedPermission = true
                if self.isAuthorized {
                    self.startRecording()
                }
            }
        }
    }
}