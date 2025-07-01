//
//  today_salaryApp.swift
//  today_salary
//
//  Created by 杜远超 on 2025/6/30.
//

import SwiftUI
import FirebaseCore

@main
struct today_salaryApp: App {
    let dataManager = DataManager.shared
    let firebaseManager = FirebaseManager.shared
    
    init() {
        // 初始化Firebase (暂时禁用)
        firebaseManager.configure()
        
        // 记录首次启动日期
        if UserDefaults.standard.object(forKey: "first_launch_date") == nil {
            UserDefaults.standard.set(Date(), forKey: "first_launch_date")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(firebaseManager)
                .onAppear {
                    // 确保数据管理器已初始化
                    dataManager.loadData()
                    
                    // 记录应用启动事件
                    firebaseManager.trackAppLaunch()
                    firebaseManager.trackDailyActiveUser()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // 记录应用进入后台事件
                    firebaseManager.trackAppBackground()
                }
        }
    }
}
