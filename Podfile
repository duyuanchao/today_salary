platform :ios, '15.0'

target 'today_salary' do
  use_frameworks!
  
  # Firebase 核心依赖
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Performance'
  pod 'Firebase/RemoteConfig'
  
  target 'today_salaryTests' do
    inherit! :search_paths
  end
  
  target 'today_salaryUITests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      # 修复沙盒权限问题
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
  
  # 修复Framework复制权限问题
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
  end
end 