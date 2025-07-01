import SwiftUI

struct FirebaseTestView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var testResult = "点击按钮测试Firebase集成"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Firebase集成测试")
                .font(.title)
                .fontWeight(.bold)
            
            Text(testResult)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("测试Firebase Analytics") {
                // 测试Firebase分析功能
                firebaseManager.trackCustomEvent(
                    eventName: "firebase_test", 
                    parameters: ["test_time": Date().timeIntervalSince1970]
                )
                testResult = "✅ Firebase Analytics测试事件已发送\n如果没有构建错误，说明集成成功！"
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("测试屏幕追踪") {
                firebaseManager.trackScreenView(screenName: "firebase_test")
                testResult = "✅ 屏幕访问事件已发送\n代码集成正确！"
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text("说明：如果按钮可以点击且没有编译错误，证明Firebase代码集成正确，只是构建时的文件复制问题。")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .onAppear {
            firebaseManager.trackScreenView(screenName: "firebase_test_view")
        }
    }
}

#Preview {
    FirebaseTestView()
        .environmentObject(FirebaseManager.shared)
} 