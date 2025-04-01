# Git 备份指南

本项目使用Git进行版本控制，特别关注`lib/`目录下的代码文件。

## 基本使用方法

### 自动备份（推荐）

使用提供的备份脚本：

```bash
./backup_lib.sh
```

这个脚本会自动检测`lib/`目录下的更改，并创建一个带有时间戳的提交。

### 手动备份

如果您想手动控制备份过程，可以使用以下Git命令：

1. 查看更改状态：
   ```bash
   git status
   ```

2. 添加`lib/`目录下的更改：
   ```bash
   git add lib/
   ```

3. 提交更改：
   ```bash
   git commit -m "描述您所做的更改"
   ```

## 查看历史版本

查看提交历史：
```bash
git log
```

查看特定文件的历史：
```bash
git log -- lib/path/to/file.dart
```

## 恢复到之前的版本

1. 查找要恢复到的提交ID：
   ```bash
   git log
   ```

2. 恢复特定文件到之前的版本：
   ```bash
   git checkout [commit-id] -- lib/path/to/file.dart
   ```

3. 恢复整个`lib/`目录到之前的版本：
   ```bash
   git checkout [commit-id] -- lib/
   ```

## 分支管理

创建新功能分支：
```bash
git checkout -b feature/new-feature
```

切换回主分支：
```bash
git checkout main
```

合并功能分支：
```bash
git merge feature/new-feature
```