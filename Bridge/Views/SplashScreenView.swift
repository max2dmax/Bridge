//// SplashScreenView.swift

import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    let gradientColors: [Color]

    @State private var showTitle = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Text("Bridge Song Book")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .opacity(showTitle ? 1 : 0)
                .scaleEffect(showTitle ? 1 : 0.95)
                .animation(.easeInOut(duration: 1.2), value: showTitle)
        }
        .onAppear {
            withAnimation { showTitle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showTitle = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isActive = false
                }
            }
        }
    }
}
//  SplashScreenView.swift
//  Bridge
//
//  Created by Max stevenson on 8/5/25.
//

