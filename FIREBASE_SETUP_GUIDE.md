# Firebase Analytics 集成指南

本指南将帮助您为Today Salary应用设置Firebase分析和监控功能。

## 🚀 快速开始

### 1. Firebase控制台设置

1. **访问Firebase控制台**
   - 打开 [Firebase Console](https://console.firebase.google.com/)
   - 使用您的Google账号登录

2. **创建新项目**
   - 点击"添加项目"
   - 输入项目名称（建议：`today-salary-tracker`）
   - 选择是否启用Google Analytics（推荐启用）
   - 完成项目创建

3. **添加iOS应用**
   - 在项目概览页面，点击iOS图标
   - 输入iOS Bundle ID：`com.yourname.today-salary`（请根据您的实际Bundle ID修改）
   - 输入应用昵称：`Today Salary`
   - 下载 `GoogleService-Info.plist` 文件

### 2. 本地项目配置

1. **替换配置文件**
   ```bash
   # 将下载的GoogleService-Info.plist文件替换项目中的占位符文件
   cp ~/Downloads/GoogleService-Info.plist ./today_salary/GoogleService-Info.plist
   ```

2. **安装依赖**
   ```bash
   # 在项目根目录下执行
   pod install
   ```

3. **打开项目**
   ```bash
   # 使用.xcworkspace文件而不是.xcodeproj
   open today_salary.xcworkspace
   ```

### 3. Xcode项目配置

1. **添加GoogleService-Info.plist到项目**
   - 在Xcode中右键点击项目
   - 选择"Add Files to today_salary"
   - 选择GoogleService-Info.plist文件
   - 确保"Add to target"勾选了主应用target

2. **验证Bundle ID**
   - 在项目设置中确认Bundle Identifier与Firebase中配置的一致

## 📊 分析功能说明

### 自动追踪的事件

#### 用户行为事件
- **应用启动**: 每次应用启动时记录
- **屏幕访问**: 追踪用户访问的各个界面
- **按钮点击**: 记录重要按钮的点击行为

#### 收入相关事件
- **收入更新**: 用户更新每日收入时
- **目标达成**: 达到每日收入目标时
- **自动计算**: 基于工作时间的自动收入计算

#### 设置相关事件
- **用户设置**: 初始设置月收入和计算方法
- **工作时间配置**: 设置工作时间和自动计算
- **发薪日设置**: 配置发薪日相关信息

#### 成就系统事件
- **成就解锁**: 解锁新成就时
- **挑战完成**: 完成日常挑战时

### 用户属性
- **收入范围**: 用户的收入水平分类
- **计算方法**: 自然日vs工作日计算
- **使用天数**: 用户使用应用的时长分类
- **是否使用工作时间功能**: 是否启用自动计算

## 🔧 Firebase控制台使用

### 1. Analytics仪表板
- **实时用户**: 查看当前活跃用户
- **用户行为**: 分析用户在应用中的行为路径
- **事件统计**: 查看各种事件的触发频率

### 2. 受众分析
- **用户画像**: 基于收入范围和使用习惯的用户分类
- **留存率**: 用户的留存情况分析
- **活跃度**: 日活、周活、月活用户统计

### 3. 自定义报告
可以创建以下自定义报告：
- **收入目标达成率**: 用户达成每日目标的比例
- **功能使用情况**: 各个功能的使用率
- **用户参与度**: 基于事件频率的参与度分析

## 🚨 Crashlytics（崩溃分析）

### 功能
- **自动崩溃报告**: 应用崩溃时自动收集错误信息
- **错误追踪**: 记录非致命错误
- **性能监控**: 追踪应用性能指标

### 查看报告
1. 在Firebase控制台选择"Crashlytics"
2. 查看崩溃报告和错误统计
3. 根据错误信息修复问题

## 📈 Performance Monitoring（性能监控）

### 自动监控指标
- **应用启动时间**: 应用冷启动和热启动的时间
- **HTTP请求**: 网络请求的响应时间
- **自定义追踪**: 重要操作的性能指标

### 自定义性能追踪
代码中已集成自定义性能追踪：
```swift
let trace = firebaseManager.startPerformanceTrace(name: "data_load")
// 执行操作
trace.stop()
```

## 🎯 关键指标说明

### 重要事件
1. **user_setup_completed**: 用户完成初始设置
2. **earnings_updated**: 收入更新（手动或自动）
3. **daily_goal_achieved**: 达成每日目标
4. **achievement_unlocked**: 解锁成就
5. **screen_view**: 屏幕访问统计

### 分析维度
- **day_of_week**: 一周中的活跃天数
- **hour_of_day**: 一天中的活跃时间
- **income_range**: 用户收入水平分类
- **calculation_method**: 收入计算方法偏好

## 🛠 故障排除

### 常见问题

1. **Firebase初始化失败**
   - 检查GoogleService-Info.plist是否正确添加到项目
   - 确认Bundle ID是否匹配

2. **事件不显示在控制台**
   - Firebase Analytics有一定延迟（最多24小时）
   - 使用Debug View查看实时事件

3. **Cocoapods依赖问题**
   ```bash
   # 清理并重新安装
   pod deintegrate
   pod clean
   pod install
   ```

### Debug模式
在开发过程中启用Debug模式：
```bash
# 添加启动参数
-FIRDebugEnabled
```

## 📝 最佳实践

### 事件命名
- 使用下划线分隔的小写字母
- 保持事件名称简洁且描述性强
- 避免使用保留字段名

### 参数设置
- 限制参数数量（最多25个）
- 参数值长度不超过100字符
- 使用有意义的参数名称

### 隐私考虑
- 不收集个人敏感信息
- 对收入金额进行范围分类而非记录具体数值
- 遵循应用隐私政策

## 🔗 相关链接

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)
- [iOS Analytics Guide](https://firebase.google.com/docs/analytics/ios/start)
- [Event Parameters Reference](https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Classes/FIRAnalytics)

## 📧 支持

如遇到问题，请检查：
1. Firebase控制台的项目设置
2. Xcode的构建日志
3. 设备的网络连接状态

---

**注意**: 请确保在发布应用前测试所有Firebase功能，并遵循相关的数据隐私法规。 