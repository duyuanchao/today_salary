//
//  today_salaryApp.swift
//  today_salary
//
//  Created by 杜远超 on 2025/6/30.
//

import SwiftUI

@main
struct today_salaryApp: App {
    let dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .onAppear {
                    // 确保数据管理器已初始化
                    dataManager.loadData()
                }
        }
    }
}
