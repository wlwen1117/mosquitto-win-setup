# Mosquitto MQTT 服务器部署包

> 📦 **版本：** Mosquitto 2.0.22 | **部署包：** v1.0 | **日期：** 2025-10-23

## 📑 目录

- [⚠️ 重要提醒](#️-重要提醒)
- [📁 文件说明](#-文件说明)
- [🚀 快速开始](#-快速开始)
  - [第一步：安装 Mosquitto](#第一步安装-mosquitto)
  - [第二步：部署配置](#第二步部署配置)
- [📦 迁移到其他Windows PC](#-迁移到其他windows-pc)
- [🔧 配置说明](#-配置说明)
- [📊 测试验证](#-测试验证)
- [🛠️ 常用命令](#️-常用命令)
- [⚠️ 常见问题](#️-常见问题)
- [📚 文档和脚本说明](#-文档和脚本说明)
- [🔒 安全建议](#-安全建议)
- [📦 版本信息](#-版本信息)

---

## ⚠️ 重要提醒

```
┌─────────────────────────────────────────────────────────────┐
│  ⚠️  安装路径必须是: E:\Services\mosquitto                  │
│                                                             │
│  所有配置文件和脚本都已预配置此路径！                        │
│  使用其他路径需要手动修改多个配置文件。                      │
└─────────────────────────────────────────────────────────────┘
```

## 📁 文件说明

```
mosquitto_setup/
├── mosquitto-2.0.22-install-windows-x64.exe  # Mosquitto installer (27MB)
├── mosquitto.conf              # Configuration file (Windows paths)
├── deploy.ps1                  # Quick deploy script (English, recommended)
├── fix_permissions.ps1         # Fix log file permission issues
├── 部署文档.md                 # Complete deployment guide (Chinese)
└── README.md                   # This file
```

## 🚀 快速开始

### 完整部署流程图

```
Step 1: 安装 Mosquitto
   ↓
   运行 mosquitto-2.0.22-install-windows-x64.exe
   ⚠️ 安装路径: E:\Services\mosquitto
   ↓
Step 2: 复制配置文件
   ↓
   Copy mosquitto.conf → E:\Services\mosquitto\
   ↓
Step 3: 运行部署脚本
   ↓
   以管理员身份运行: .\deploy.ps1
   自动完成：目录创建、权限设置、防火墙、服务安装
   ↓
Step 4: 测试连接
   ↓
   mosquitto_sub.exe -h localhost -t test/# -v
   ↓
✅ 部署完成！
```

### 第一步：安装 Mosquitto

⚠️ **重要：必须安装到指定目录 `E:\Services\mosquitto`**

1. **运行安装程序：**
   - 双击 `mosquitto-2.0.22-install-windows-x64.exe`
   
2. **选择安装路径：**
   ```
   安装路径必须设置为: E:\Services\mosquitto
   ```
   
3. **为什么必须是这个路径？**
   - ✅ 配置文件 `mosquitto.conf` 中所有路径已预配置为此目录
   - ✅ 部署脚本 `deploy.ps1` 默认使用此路径
   - ✅ 避免后续手动修改配置文件中的多处路径引用
   
4. **如果必须使用其他路径：**
   - ⚠️ 需要手动编辑 `mosquitto.conf` 文件
   - ⚠️ 需要修改 `deploy.ps1` 中的 `$installPath` 变量
   - ⚠️ 需要替换配置文件中所有 `E:\Services\mosquitto` 路径

### 第二步：部署配置

#### 前提条件
- ✅ Mosquitto 已安装到 `E:\Services\mosquitto`
- ✅ 具有管理员权限
- ✅ Windows 10/11 或 Windows Server 2016+

### 一键部署（推荐）

#### 步骤1：复制配置文件

```powershell
# 复制配置文件到安装目录
Copy-Item "mosquitto.conf" "E:\Services\mosquitto\" -Force
```

或者手动复制：
1. 打开 `mosquitto_setup` 文件夹
2. 复制 `mosquitto.conf` 文件
3. 粘贴到 `E:\Services\mosquitto\` 目录

#### 步骤2：以管理员身份运行 PowerShell

**重要：** 必须使用管理员权限！

1. 按 `Win + X`，选择 **"Windows PowerShell (管理员)"**
2. 或右键点击 PowerShell 图标，选择 **"以管理员身份运行"**

#### 步骤3：执行部署脚本

```powershell
# 进入部署目录
cd E:\05_LZBOX\lzbox-lzbox_app-main\lzbox-lzbox_app-main\lzbox_app\mosquitto_setup

# 执行部署脚本（推荐 - 无编码问题）
.\deploy.ps1
```

**脚本执行过程（约1-2分钟）：**

```
[1/7] Creating directory structure...
      ✓ 创建 data、log、conf.d 目录

[2/7] Checking configuration file...
      ✓ 验证配置文件完整性

[3/7] Setting directory permissions...
      ✓ 设置文件系统权限

[4/7] Configuring firewall...
      ✓ 开放 1883 端口

[5/7] Configuring Windows service...
      ✓ 安装 Mosquitto 服务

[6/7] Starting service...
      ✓ 启动服务

[7/7] Verifying deployment...
      ✓ 功能测试通过

========================================
Deployment Complete!
========================================
```

#### 步骤4：验证部署

脚本会自动显示：
- ✅ 服务状态：Running
- ✅ MQTT 端口：1883
- ✅ 本机 IP 地址列表
- ✅ 快速测试命令

## 📊 测试验证

### 1. 检查服务状态

```powershell
# 查看服务
Get-Service mosquitto

# 查看端口
netstat -ano | findstr :1883

# 查看日志
Get-Content E:\Services\mosquitto\log\mosquitto.log -Tail 20
```

### 2. 功能测试

**终端1 - 订阅：**
```powershell
cd E:\Services\mosquitto
.\mosquitto_sub.exe -h localhost -t test/# -v
```

**终端2 - 发布：**
```powershell
cd E:\Services\mosquitto
.\mosquitto_pub.exe -h localhost -t test/topic -m "Hello MQTT"
```

### 3. 远程连接测试

在另一台PC上（替换为实际IP）：
```powershell
.\mosquitto_sub.exe -h 192.168.1.100 -t test/# -v
```

## 🛠️ 常用命令

### 服务管理
```powershell
net start mosquitto      # 启动服务
net stop mosquitto       # 停止服务
sc query mosquitto       # 查询状态
```

### 测试工具
```powershell
# 订阅所有主题
.\mosquitto_sub.exe -h localhost -t # -v

# 订阅特定主题
.\mosquitto_sub.exe -h localhost -t sensor/temperature -v

# 发布消息
.\mosquitto_pub.exe -h localhost -t sensor/temperature -m "25.5"

# 带用户认证的订阅
.\mosquitto_sub.exe -h localhost -t test/# -u admin -P password -v
```

### 日志查看
```powershell
# 查看最新日志
Get-Content E:\Services\mosquitto\log\mosquitto.log -Tail 50

# 实时监控日志
Get-Content E:\Services\mosquitto\log\mosquitto.log -Wait -Tail 20

# 搜索错误
Get-Content E:\Services\mosquitto\log\mosquitto.log | Select-String "error"
```

#### ⚠️ 如果出现权限拒绝错误

如果查看日志时遇到 `Access Denied` 或 `拒绝访问` 错误：

```powershell
Get-Content : 对路径"E:\Services\mosquitto\log\mosquitto.log"的访问被拒绝。
```

**解决方案：**

1. **方法1：使用管理员权限运行（推荐）**
   ```powershell
   # 关闭当前PowerShell
   # 右键点击PowerShell图标，选择"以管理员身份运行"
   # 然后再次查看日志
   Get-Content E:\Services\mosquitto\log\mosquitto.log -Tail 50
   ```

2. **方法2：运行权限修复脚本**
   ```powershell
   # 以管理员身份运行PowerShell
   cd E:\05_LZBOX\lzbox-lzbox_app-main\lzbox-lzbox_app-main\lzbox_app\mosquitto_setup
   .\fix_permissions.ps1
   ```
   
   脚本会自动：
   - ✅ 为当前用户添加完全控制权限
   - ✅ 为管理员组添加完全控制权限
   - ✅ 为用户组添加读取权限

3. **方法3：使用CMD命令（无需管理员）**
   ```powershell
   cmd /c type E:\Services\mosquitto\log\mosquitto.log
   ```

4. **方法4：使用记事本打开**
   ```powershell
   notepad E:\Services\mosquitto\log\mosquitto.log
   ```

## ⚠️ 常见问题

### 1. ❌ 安装到了错误的目录

**症状：** 部署脚本找不到 Mosquitto，或配置文件路径错误

**解决方案：**

**选项A：重新安装到正确目录（推荐）**
```powershell
# 1. 卸载当前安装
# 控制面板 -> 程序和功能 -> 卸载 Mosquitto

# 2. 重新运行安装程序
# 安装时选择路径: E:\Services\mosquitto
```

**选项B：修改配置和脚本以适应当前路径**
```powershell
# 假设安装到了 C:\Program Files\mosquitto

# 1. 修改 mosquitto.conf 中的所有路径
#    将所有 E:\Services\mosquitto 替换为实际安装路径
#    - persistence_location
#    - log_dest file
#    - password_file (如果有)

# 2. 修改 deploy.ps1 第42行
#    $installPath = "C:\Program Files\mosquitto"
```

### 2. 服务无法启动

**检查配置文件语法：**
```powershell
cd E:\Services\mosquitto
.\mosquitto.exe -c mosquitto.conf -v
```

**检查必要目录是否存在：**
```powershell
# 检查目录
Test-Path E:\Services\mosquitto\data\
Test-Path E:\Services\mosquitto\log\

# 如果不存在，创建它们
New-Item -ItemType Directory -Force -Path E:\Services\mosquitto\data
New-Item -ItemType Directory -Force -Path E:\Services\mosquitto\log
```

**查看错误信息：**
```powershell
# 查看Windows事件日志
Get-EventLog -LogName Application -Source mosquitto -Newest 10
```

### 3. 端口被占用

**症状：** 服务启动失败，提示端口1883已被使用

**解决方案：**
```powershell
# 查找占用进程
netstat -ano | findstr :1883

# 结束进程（替换<PID>为实际进程ID）
taskkill /PID <PID> /F

# 或修改配置使用其他端口
# 编辑 mosquitto.conf: listener 11883 0.0.0.0
```

### 4. 防火墙阻止连接

**症状：** 本机可以连接，但其他机器无法连接

**解决方案：**
```powershell
# 以管理员身份添加防火墙规则
New-NetFirewallRule -DisplayName "Mosquitto MQTT" -Direction Inbound -LocalPort 1883 -Protocol TCP -Action Allow

# 检查规则是否生效
Get-NetFirewallRule -DisplayName "Mosquitto MQTT"

# 或通过Windows防火墙界面手动添加
# 控制面板 -> Windows Defender 防火墙 -> 高级设置 -> 入站规则 -> 新建规则
```

### 5. 无法远程连接

**检查清单：**
- [ ] 服务是否运行：`sc query mosquitto`
- [ ] 防火墙是否开放1883端口：`Get-NetFirewallRule -DisplayName "Mosquitto MQTT"`
- [ ] 配置是否监听所有接口：检查 `listener 1883 0.0.0.0`
- [ ] 网络是否互通：`ping <服务器IP>`
- [ ] 端口是否监听：`netstat -ano | findstr :1883`

**测试步骤：**
```powershell
# 1. 在服务器上测试本地连接
cd E:\Services\mosquitto
.\mosquitto_sub.exe -h localhost -t test/# -v

# 2. 在客户端测试远程连接（替换IP）
.\mosquitto_sub.exe -h 192.168.1.100 -t test/# -v

# 3. 测试端口连通性
Test-NetConnection -ComputerName 192.168.1.100 -Port 1883
```

### 6. 日志文件权限被拒绝

**症状：** 无法查看或访问 `mosquitto.log` 文件

**解决方案：** 参见上方 [日志查看 - 权限拒绝错误](#-如果出现权限拒绝错误) 部分

### 7. 服务自动停止

**症状：** 服务启动后自动停止

**排查步骤：**
```powershell
# 1. 检查配置文件
.\mosquitto.exe -c mosquitto.conf -v

# 2. 临时前台运行查看错误
.\mosquitto.exe -c mosquitto.conf -v

# 3. 检查日志（使用管理员权限）
Get-Content log\mosquitto.log -Tail 50

# 4. 检查端口是否被占用
netstat -ano | findstr :1883
```

## 📚 文档和脚本说明

### 核心文件

| 文件 | 用途 | 何时使用 |
|------|------|---------|
| `mosquitto-2.0.22-install-windows-x64.exe` | Mosquitto安装程序 | 首次部署 |
| `mosquitto.conf` | 预配置的配置文件 | 部署时复制到安装目录 |
| `deploy.ps1` | 自动化部署脚本 | 配置服务、防火墙、权限 |
| `fix_permissions.ps1` | 权限修复脚本 | 日志访问被拒绝时 |
| `部署文档.md` | 完整部署指南 | 详细步骤和说明 |

### 快速参考

**安装步骤：**
1. 运行 `mosquitto-2.0.22-install-windows-x64.exe`，安装到 `E:\Services\mosquitto`
2. 复制 `mosquitto.conf` 到安装目录
3. 以管理员身份运行 `.\deploy.ps1`

**服务管理：**
- 启动：`net start mosquitto`
- 停止：`net stop mosquitto`
- 状态：`sc query mosquitto`

**测试连接：**
- 本地：`mosquitto_sub.exe -h localhost -t test/# -v`
- 远程：`mosquitto_sub.exe -h <IP> -t test/# -v`

**解决权限问题：**
- 以管理员身份运行 PowerShell
- 或执行 `.\fix_permissions.ps1`



## 🔗 相关链接

**官方资源：**
- Mosquitto 官网: https://mosquitto.org/
- 官方文档: https://mosquitto.org/documentation/
- GitHub: https://github.com/eclipse/mosquitto

**本地文档：**
- [部署文档.md](部署文档.md) - 详细部署指南
- [mosquitto.conf](mosquitto.conf) - 配置文件（含注释）

**部署包信息：**
- 版本：1.0
- 创建日期：2025-10-23
- Mosquitto 版本：2.0.22
- 预配置路径：E:\Services\mosquitto

