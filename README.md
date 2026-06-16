# MacMonitor

一个专为 macOS 设计的原生状态栏系统监控小程序。使用 Swift 与 AppKit 编写，具有极高的运行效率和极低的系统资源占用。

## 功能特性

- 🔥 **CPU 温度监控**：专为 Apple Silicon（M1, M2, M3, M4, M5 等）芯片优化，通过 IOHID 系统底层接口**免 Sudo 权限**读取 CPU 核心的最高温度。
- ❄️ **内置固态硬盘（SSD）温度监控**：实时读取内置固态硬盘 NAND 闪存控制器的最高温度。
- 🔌 **外接硬盘温度监控 (可选)**：通过集成 `smartctl` 诊断工具，支持实时获取移动硬盘/外接固态硬盘的温度。
- 💻 **CPU 使用率**：基于 Darwin 内核主机统计数据，实时计算 CPU 使用百分比。
- 💾 **磁盘空间容量**：实时展示主硬盘分区的使用百分比、已用空间及剩余可用空间。
- 🎨 **原生外观设计**：状态栏与下拉菜单支持苹果原生的 SF Symbols 图标，完美适配 macOS 浅色/深色主题，无 Dock 栏图标干扰。

## 目录结构

```
mac-monitor/
├── src/
│   ├── TemperatureReader.swift  # 负责读取 CPU 和内置磁盘温度
│   ├── ExternalDiskReader.swift # 负责读取外置物理磁盘温度 (S.M.A.R.T. 模式)
│   ├── CPUReader.swift          # 负责计算 CPU 使用率
│   ├── DiskReader.swift         # 负责计算主磁盘空间占用
│   ├── MenuBarApp.swift         # 负责管理状态栏按钮和下拉菜单 UI (动态更新外接盘)
│   ├── main.swift               # 应用程序启动入口
│   └── Info.plist               # 隐藏 Dock 图标、以后台 Agent 运行的配置文件
├── build.sh                     # 一键编译、打包与启动脚本
└── .gitignore                   # 排除构建二进制及系统临时文件
```

## 构建与运行

打开终端并进入项目根目录，运行以下脚本即可完成编译、打包和运行：

```bash
chmod +x build.sh
./build.sh
```

- 编译生成的应用位于 `build/MacMonitor.app`。
- 首次启动后，温度会自动显示在 macOS 的右上角状态栏。

## 外置磁盘温度监测配置 (可选)

由于读取外置硬盘的 `S.M.A.R.T.` 温度属于底层硬件操作，需要 `smartctl` 工具以及管理员 (`sudo`) 权限。为了让小程序能在后台免密运行，请按以下步骤配置：

1. **安装 `smartctl` 工具**：
   ```bash
   brew install smartmontools
   ```

2. **配置免密码使用 `smartctl`**：
   运行命令编辑 `sudoers` 配置文件：
   ```bash
   sudo visudo
   ```
   在文件末尾追加以下这行内容（将 `hzhang` 替换为你的 macOS 当前用户名）：
   ```text
   hzhang ALL=(ALL) NOPASSWD: /opt/homebrew/bin/smartctl
   ```
   *(如果是在 Intel Mac 上通过 Homebrew 安装的，请将路径改为 `/usr/local/bin/smartctl`)*

*配置完成后，当接入外挂硬盘时，下拉菜单会自动检测到它并显示实时温度。未配置或未接入外接盘时，程序会自动忽略或安全显示为 `N/A`，不会影响其他功能的正常运行。*

## 退出应用

点击状态栏上的温度数值，在下拉菜单中点击 **Quit** 即可完全退出。
