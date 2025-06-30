//
//  ContentView.swift
//  today_salary
//
//  Created by 杜远超 on 2025/6/30.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        Group {
            if dataManager.userProfile.isSetup {
                MainView()
            } else {
                WelcomeView()
            }
        }
        .onAppear {
            // 确保数据管理器已加载
            dataManager.loadData()
        }
    }
}

#Preview {
    ContentView()
}
