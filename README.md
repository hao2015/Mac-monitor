# MacMonitor

一个专为 macOS 设计的原生状态栏系统监控小程序。使用 Swift 与 AppKit 编写，具有极高的运行效率和极低的系统资源占用。

## 功能特性

- 🔥 **CPU 温度监控**：专为 Apple Silicon（M1, M2, M3, M4, M5 等）芯片优化，通过 IOHID 系统底层接口**免 Sudo 权限**读取 CPU 核心的最高温度。
- ❄️ **固态硬盘（SSD）温度监控**：实时读取固态硬盘 NAND 闪存控制器的最高温度。
- 💻 **CPU 使用率**：基于 Darwin 内核主机统计数据，实时计算 CPU 使用百分比。
- 💾 **磁盘空间容量**：实时展示主硬盘分区的使用百分比、已用空间及剩余可用空间。
- 🎨 **原生外观设计**：状态栏与下拉菜单支持苹果原生的 SF Symbols 图标，完美适配 macOS 浅色/深色主题，无 Dock 栏图标干扰。

## 目录结构

```
mac-monitor/
├── src/
│   ├── TemperatureReader.swift  # 负责读取 CPU 和 磁盘(NAND) 温度
│   ├── CPUReader.swift          # 负责计算 CPU 使用率
│   ├── DiskReader.swift         # 负责计算磁盘空间占用
│   ├── MenuBarApp.swift         # 负责管理状态栏按钮和下拉菜单 UI
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

## 退出应用

点击状态栏上的温度数值，在下拉菜单中点击 **Quit** 即可完全退出。
