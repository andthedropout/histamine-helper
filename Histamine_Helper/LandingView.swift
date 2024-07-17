//
//  LandingView.swift
//  SwiftUI-AI-Wrapper
//
//  Created by _ on 7/9/24.
//

import SwiftUI

struct LandingView: View {
    @Binding var showLanding: Bool
    @State private var currentStep = 0
    
    let steps = [
        IntroStep(image: "camera.viewfinder", title: "Snap & Scan", description: "Take a photo of food labels (or the food itself!) for instant analysis."),
        IntroStep(image: "bubble.left.and.bubble.right", title: "Ask Questions", description: "Get answers to any food sensitivity-related questions, or ask for tasty substitutions and recipes."),
        IntroStep(image: "list.bullet.clipboard", title: "Get Detailed Info", description: "Our AI model is finetuned to give you the most accurate and up-to-date histamine sensitivity information."),
        IntroStep(image: "person.fill.checkmark", title: "Make Better Choices", description: "Easily decide which foods are safe for you! Your chat history is saved to revisit later.")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Updated gradient with fresh, green colors
                LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.4, green: 0.8, blue: 0.4, alpha: 1)), Color(#colorLiteral(red: 0.2, green: 0.7, blue: 0.3, alpha: 1)), Color(#colorLiteral(red: 0.1, green: 0.6, blue: 0.2, alpha: 1))]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    // Updated app name/logo section
                    VStack(spacing: 8) { // Set a small spacing
                        HStack(spacing: 10) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 28)) // Reduced from 40
                                .foregroundColor(.white)
                            Text("Histamine Helper")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 50)

                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 300, height: 3)
                    }
                    
                    TabView(selection: $currentStep) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            IntroStepView(step: steps[index])
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Change to .never
                    .frame(height: geometry.size.height * 0.6)
                    
                    // Add custom page indicator
                    HStack(spacing: 12) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 10, height: 10)
                                .scaleEffect(index == currentStep ? 1.2 : 1.0)
                                .animation(.spring(), value: currentStep)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Updated button style
                    Button(action: {
                        if currentStep < steps.count - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            showLanding = false
                        }
                    }) {
                        Text(currentStep < steps.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 70)
                    

                }
            }
        }
    }
}

struct IntroStep: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

struct IntroStepView: View {
    let step: IntroStep
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Updated icon presentation
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 150, height: 150)
                
                Image(systemName: step.image)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            Text(step.title)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(step.description)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .frame(maxWidth: 300)
        }
        .padding()
        .scaleEffect(isAnimating ? 1 : 0.9)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                isAnimating = true
            }
        }
    }
}