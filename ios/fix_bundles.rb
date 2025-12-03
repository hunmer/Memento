#!/usr/bin/env ruby
# 自动修复所有缺失的 bundle 占位文件

require 'fileutils'

# 查找所有 bundle 目录
bundle_dirs = `find build/ios -name "*.bundle" -type d`.split("\n")

puts "找到 #{bundle_dirs.length} 个 bundle 目录"

missing_count = 0

bundle_dirs.each do |bundle_dir|
  # 获取 bundle 名称（通常是目录名）
  bundle_name = File.basename(bundle_dir)

  # 检查是否缺少以 bundle 名称命名的文件
  expected_file = "#{bundle_dir}/#{bundle_name}"

  unless File.exist?(expected_file)
    puts "创建缺失文件: #{expected_file}"
    File.write(expected_file, "")
    missing_count += 1
  end
end

puts "\n总共创建了 #{missing_count} 个缺失的占位文件！"
