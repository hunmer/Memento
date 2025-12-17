# 快速安装

Memento 提供了多种安装方式，请根据您的设备类型选择合适的安装方法。

## 常规安装

### Android 设备

**方法一：APK 安装包**

1. 访问 [GitHub Releases](https://github.com/hunmer/Memento/releases)
2. 下载最新版本的 APK 文件
3. 在设备上允许「未知来源」应用安装
4. 点击 APK 文件进行安装

**方法二：应用商店（待上架）**

- Google Play Store（即将推出）
- 国内各大应用商店（即将推出）

### iOS 设备

**方法一：TestFlight（推荐）**

1. 在 iPhone/iPad 上安装 TestFlight
2. 访问 [GitHub Releases](https://github.com/hunmer/Memento/releases)
3. 下载 TestFlight 邀请链接或二维码
4. 通过 TestFlight 安装应用

**方法二：自签名安装（见下方详细说明）**

### Windows 设备

1. 访问 [GitHub Releases](https://github.com/hunmer/Memento/releases)
2. 下载 Windows 安装包（.exe 或 .msi）
3. 运行安装程序并按照提示完成安装

### macOS 设备

1. 访问 [GitHub Releases](https://github.com/hunmer/Memento/releases)
2. 下载 macOS 版本（.dmg）
3. 打开 DMG 文件并将应用拖到 Applications 文件夹
4. 首次运行需要在「系统偏好设置 > 安全性与隐私」中允许运行

### Linux 设备

1. 访问 [GitHub Releases](https://github.com/hunmer/Memento/releases)
2. 下载对应的 AppImage 或 deb 包
3. 运行以下命令安装：
   ```bash
   # AppImage
   chmod +x Memento-linux.AppImage
   ./Memento-linux.AppImage

   # 或 deb 包
   sudo dpkg -i Memento-linux.deb
   ```

### Web 版本

直接访问：[https://hunmer.github.io/Memento](https://hunmer.github.io/Memento)

---

## iOS 自签名安装

如果您无法通过 TestFlight 安装，可以使用自签名的方式安装应用。

### 准备工作

1. **电脑**：需要一台 Mac 或 Windows 电脑
2. **iOS 设备**：iPhone 或 iPad
3. **Apple ID**：您的 Apple 账户
4. **数据线**：用于连接设备与电脑

### 安装步骤

#### 使用 Mac（推荐）

**第一步：安装爱思助手**

1. 下载爱思助手：[https://www.i4.cn/](https://www.i4.cn/)
2. 安装并启动爱思助手
3. 使用数据线连接 iOS 设备到电脑
4. 在设备上点击「信任此电脑」

**第二步：安装应用**

1. 在爱思助手中找到「应用游戏」标签
2. 搜索「Memento」或点击「导入安装」
3. 选择从 GitHub 下载的 IPA 文件
4. 点击「安装」并等待完成

#### 使用 Windows

**方法一：爱思助手（推荐）**

1. 下载爱思助手：[https://www.i4.cn/](https://www.i4.cn/)
2. 安装并连接设备（同 Mac 步骤）
3. 在「应用游戏」中 文件

**方法导入安装 IPA二：Sideloadly**

1. 下载 Sideloadly：[https://sideloadly.io/](https://sideloadly.io/)
2. 使用您的 Apple ID 登录
3. 连接设备并选择 IPA 文件
4. 点击「Start」进行安装

### 注意事项

1. **证书有效期**：自签名应用通常有 7 天有效期，到期后需要重新安装
2. **Apple ID**：使用自己的 Apple ID，避免账号安全风险
3. **网络要求**：安装过程中需要连接互联网
4. **信任证书**：安装完成后，在「设置 > 通用 > VPN 与设备管理」中信任企业证书

### 常见问题

**Q：安装后无法打开应用？**
A：请检查是否已信任证书，在「设置 > 通用 > VPN 与设备管理」中点击信任。

**Q：应用经常闪退？**
A：可能是证书过期，请重新安装最新版本。

**Q：如何更新应用？**
A：需要卸载旧版本后重新安装新版本。

---

## 获取帮助

如果安装过程中遇到问题：

1. 查看 [GitHub Issues](https://github.com/hunmer/Memento/issues)
2. 加入用户交流群
3. 提交新的 Issue 描述问题

---

## 系统要求

- **Android**: Android 7.0+ (API Level 24)
- **iOS**: iOS 12.0+
- **Windows**: Windows 10 或更高版本
- **macOS**: macOS 10.14 或更高版本
- **Linux**: 大多数现代 Linux 发行版
- **Web**: 现代浏览器（Chrome 90+、Safari 14+、Firefox 88+）
