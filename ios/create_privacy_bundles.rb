#!/usr/bin/env ruby

# 创建缺失的 Privacy Manifest Bundle 文件的脚本
# 这是针对 Xcode 16.2 和 Flutter 兼容性问题的临时解决方案

require 'fileutils'

# 需要创建 privacy bundle 的插件列表
plugins = %w[
  url_launcher_ios
  video_player_avfoundation
  shared_preferences_foundation
  share_plus
  record_ios
  quill_native_bridge_ios
  permission_handler_apple
  path_provider_foundation
  package_info_plus
  image_picker_ios
]

# 构建配置
configs = ['Debug-iphonesimulator', 'Debug-iphoneos', 'Release-iphoneos', 'Release-iphonesimulator']

configs.each do |config|
  plugins.each do |plugin|
    bundle_dir = "build/ios/#{config}/#{plugin}/#{plugin}_privacy.bundle"
    FileUtils.mkdir_p(bundle_dir)
    
    # 创建一个占位文件
    File.write("#{bundle_dir}/#{plugin}_privacy", "")
    
    puts "创建: #{bundle_dir}"
  end
end

puts "\n所有 Privacy Bundle 占位文件已创建完成！"
