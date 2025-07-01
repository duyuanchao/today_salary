//
//  ContentView.swift
//  today_salary
//
//  Created by 杜远超 on 2025/6/30.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var isAppReady = false
    
    var body: some View {
        Group {
            if !isAppReady {
                // 启动画面，避免在数据未加载完成时显示空白界面
                LaunchScreen()
            } else if dataManager.userProfile.isSetup {
                MainView()
            } else {
                WelcomeView()
            }
        }
        .onAppear {
            initializeApp()
        }
    }
    
    private func initializeApp() {
        // 性能优化：预加载触觉反馈
        HapticManager.prepare()
        
        // 确保数据管理器已加载
        dataManager.loadData()
        
        // 延迟一小段时间确保UI准备就绪
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAppReady = true
            }
        }
    }
}

// MARK: - 启动画面
struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignTokens.Colors.background, DesignTokens.Colors.surface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(DesignTokens.Colors.primary)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("Today Salary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .opacity(opacity)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                    .scaleEffect(1.2)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ContentView()
}
