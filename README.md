# 人生Git - Personal Goal Management App

<div align="center">
  <img src="AppStore/AppIcon-1024x1024.png" alt="人生Git Logo" width="200" height="200">
  
  **用Git的方式管理你的人生目标**
  
  [![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
  [![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
  [![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green.svg)](https://developer.apple.com/swiftui/)
  [![SwiftData](https://img.shields.io/badge/SwiftData-1.0+-purple.svg)](https://developer.apple.com/documentation/swiftdata/)
  [![License](https://img.shields.io/badge/License-MIT-red.svg)](LICENSE)
</div>

## 📖 项目简介

人生Git是一款创新的个人目标管理应用，将程序员熟悉的Git版本控制概念巧妙地应用到人生目标管理中。你的人生就是一个完整的Git项目，主线是master分支，每个新目标都可以创建独立的分支进行管理。

### 🎯 核心理念

- **分支管理**: 每个目标都是独立的分支，可以专注执行
- **AI智能规划**: 使用Deepseek-R1 AI将大目标拆解成可执行的小任务
- **进展记录**: 通过提交记录每日进展，积少成多实现目标
- **成就合并**: 完成目标后合并到主干，见证人生版本升级
- **可视化追踪**: 直观的进度展示和成长轨迹记录

## ✨ 主要功能

### MVP版本 (v1.0)
- [x] **基础分支管理** - 创建、查看、切换目标分支
- [x] **AI任务拆解** - Deepseek-R1智能生成任务计划
- [x] **简单提交系统** - 记录日常进展和学习心得
- [x] **主干视图** - 展示人生主线和基本统计
- [x] **基础合并功能** - 完成目标后合并到主干
- [x] **本地数据存储** - 基于SwiftData的数据持久化
- [x] **用户引导** - 完整的新手引导流程
- [x] **错误处理** - 优雅的错误处理和用户反馈

### 计划功能 (v2.0+)
- [ ] **日程计划模块** - 根据任务计划生成具体日程安排
- [ ] **高级AI功能** - 复盘报告、进度建议、智能优化
- [ ] **标签系统** - 为重要人生节点打标签
- [ ] **统计分析** - 详细的目标完成情况和成长趋势
- [ ] **iCloud同步** - 多设备数据同步
- [ ] **数据导出** - 支持多种格式的数据导出

## 🏗️ 技术架构

### 架构模式
- **MVVM**: Model-View-ViewModel架构模式
- **SwiftUI**: 声明式UI框架
- **SwiftData**: iOS 17+原生ORM框架
- **Swift Concurrency**: async/await异步编程

### 核心技术栈
- **平台**: iOS 17.0+
- **语言**: Swift 5.9+
- **UI框架**: SwiftUI 5.0+
- **数据层**: SwiftData 1.0+
- **AI服务**: Deepseek-R1 API
- **网络**: URLSession + async/await

### 项目结构
```
LifeGit/
├── LifeGit.xcworkspace/           # 工作空间文件 (在Xcode中打开此文件)
├── LifeGit.xcodeproj/             # 应用项目文件
├── LifeGit/                       # 应用目标 (最小化)
│   ├── App/                       # 应用入口
│   ├── Models/                    # 数据模型
│   │   ├── Core/                  # 核心业务模型
│   │   ├── Enums/                 # 枚举定义
│   │   └── Extensions/            # 模型扩展
│   ├── Views/                     # SwiftUI视图
│   │   ├── Master/                # 主干相关视图
│   │   ├── Branch/                # 分支管理视图
│   │   ├── TaskPlan/              # 任务计划视图
│   │   ├── Commit/                # 提交相关视图
│   │   ├── Common/                # 通用UI组件
│   │   └── Onboarding/            # 用户引导
│   ├── ViewModels/                # 业务逻辑层
│   ├── Services/                  # 外部服务集成
│   ├── Repositories/              # 数据访问层
│   ├── Utils/                     # 工具类和扩展
│   ├── Resources/                 # 资源文件
│   └── Assets.xcassets/           # 应用级资源
├── LifeGitPackage/                # 🚀 主要开发区域
│   ├── Package.swift             # 包配置
│   ├── Sources/LifeGitFeature/   # 功能代码
│   └── Tests/LifeGitFeatureTests/ # 单元测试
├── LifeGitTests/                  # 单元和集成测试
├── LifeGitUITests/                # UI自动化测试
├── Config/                        # 构建配置
├── AppStore/                      # App Store资源
├── Release/                       # 发布相关文档
└── Legal/                         # 法律文档
```

## 🚀 快速开始

### 环境要求
- Xcode 15.0+
- iOS 17.0+ 模拟器或设备
- macOS 14.0+ (开发环境)

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/your-username/LifeGit.git
   cd LifeGit
   ```

2. **打开工作空间**
   ```bash
   open LifeGit.xcworkspace
   ```

3. **配置AI服务**
   - 在`Config/Secrets.xcconfig`中配置Deepseek API密钥
   - 或在运行时通过设置界面配置

4. **运行项目**
   - 选择目标设备或模拟器
   - 按`Cmd+R`运行项目

### 配置说明

#### 构建配置 (XCConfig)
构建设置通过`Config/`目录中的XCConfig文件管理：
- `Config/Shared.xcconfig` - 通用设置 (Bundle ID, 版本, 部署目标)
- `Config/Debug.xcconfig` - 调试特定设置
- `Config/Release.xcconfig` - 发布特定设置
- `Config/Tests.xcconfig` - 测试特定设置

#### 权限管理
应用功能通过声明式权限文件管理：
- `Config/LifeGit.entitlements` - 所有应用权限和功能

#### AI服务配置
```swift
// 在DeepseekR1Client中配置API密钥
private let apiKey = "your-deepseek-api-key"
private let baseURL = "https://api.deepseek.com/v1"
```

## 🧪 测试

### 运行测试
```bash
# 运行所有测试
xcodebuild test -workspace LifeGit.xcworkspace -scheme LifeGit -destination 'platform=iOS Simulator,name=iPhone 15'

# 运行特定测试套件
xcodebuild test -workspace LifeGit.xcworkspace -scheme LifeGit -only-testing:LifeGitTests/EndToEndTests
```

### 测试覆盖率
- 单元测试覆盖率: 80%+
- 集成测试覆盖率: 60%+
- 端到端测试: 完整用户流程覆盖

### 测试结构
- **单元测试**: `LifeGitTests/` - 业务逻辑和数据模型测试
- **功能测试**: `LifeGitPackage/Tests/LifeGitFeatureTests/` - Swift Testing框架
- **UI测试**: `LifeGitUITests/` - XCUITest框架
- **测试计划**: `LifeGit.xctestplan` - 协调所有测试

### 测试类型
- **端到端测试**: 完整用户流程测试 (`EndToEndTests.swift`)
- **错误场景测试**: 网络异常和AI服务失败测试 (`ErrorScenarioTests.swift`)
- **边界测试**: 边界条件和极限情况测试 (`BoundaryCaseTests.swift`)
- **性能测试**: 启动时间和响应性能测试
- **集成测试**: 组件间集成测试 (`BusinessLogicIntegrationTests.swift`)

## 📱 使用指南

### 基本流程
1. **首次启动**: 查看新手引导，了解基本概念
2. **创建目标**: 输入目标名称和描述
3. **AI生成任务**: 系统自动生成结构化任务计划
4. **确认计划**: 查看、修改或重新生成任务计划
5. **执行任务**: 开始执行任务，记录每日进展
6. **跟踪进度**: 查看任务完成状态和整体进度
7. **完成目标**: 所有任务完成后合并到主干

### 核心概念
- **Master分支**: 人生主线，记录所有完成的目标
- **目标分支**: 每个目标对应一个独立分支
- **任务计划**: AI生成的结构化任务列表
- **提交记录**: 记录每日进展和学习心得
- **分支合并**: 目标完成后合并到主干

## 🔧 开发指南

### AI助手规则文件
本项目包含针对流行AI编程助手的**规则文件**，建立了现代iOS开发的编码标准、架构模式和最佳实践：

- **Claude Code**: `CLAUDE.md` - Claude Code规则
- **Cursor**: `.cursor/*.mdc` - Cursor特定规则
- **GitHub Copilot**: `.github/copilot-instructions.md` - GitHub Copilot规则

### 代码规范
- 遵循Swift官方编码规范
- 使用SwiftLint进行代码检查
- 函数长度不超过50行
- 类长度不超过500行
- 拥抱纯SwiftUI状态管理模式
- 使用Swift 6+并发特性

### 提交规范
```
feat: 添加新功能
fix: 修复bug
docs: 更新文档
style: 代码格式调整
refactor: 代码重构
test: 添加测试
chore: 构建过程或辅助工具的变动
```

### 分支策略
- `main`: 主分支，稳定版本
- `develop`: 开发分支
- `feature/*`: 功能分支
- `release/*`: 发布分支
- `hotfix/*`: 热修复分支

### 添加依赖
编辑`LifeGitPackage/Package.swift`添加SPM依赖：
```swift
dependencies: [
    .package(url: "https://github.com/example/SomePackage", from: "1.0.0")
],
targets: [
    .target(
        name: "LifeGitFeature",
        dependencies: ["SomePackage"]
    ),
]
```

## 📊 性能指标

### 性能要求
- 应用启动时间: < 2秒
- UI响应时间: < 1秒
- AI任务生成: < 10秒
- 分支切换: < 2秒
- 内存使用: < 100MB

### 监控指标
- 崩溃率: < 0.1%
- ANR率: < 0.05%
- 网络成功率: > 95%
- AI服务成功率: > 90%

## 🛡️ 隐私和安全

### 数据保护
- 所有个人数据本地存储
- 敏感数据加密保护
- 网络传输HTTPS加密
- 不收集个人身份信息

### AI服务
- 仅在用户主动使用时调用
- 不永久存储用户数据
- 匿名化处理用户输入
- 支持离线模式

## 🚀 发布流程

### 发布检查清单
详细的发布检查清单请参考 `Release/ReleaseChecklist.md`，包括：
- 视觉资源准备
- 应用配置检查
- 功能测试验证
- 性能优化确认
- App Store准备

### 代码审查
代码审查指南请参考 `Release/CodeReviewGuidelines.md`，涵盖：
- 架构和设计合规性
- 安全性检查
- 性能优化
- 测试覆盖
- 代码质量

## 📄 法律文档

- **隐私政策**: `Legal/PrivacyPolicy.md`
- **服务条款**: `Legal/TermsOfService.md`
- **许可证**: `LICENSE` (MIT许可证)

## 🤝 贡献指南

我们欢迎社区贡献！请查看[CONTRIBUTING.md](CONTRIBUTING.md)了解如何参与项目开发。

### 贡献方式
- 报告bug和问题
- 提出功能建议
- 提交代码改进
- 完善文档
- 分享使用经验

## 📞 联系我们

- **官方网站**: https://lifegit.app
- **邮箱**: contact@lifegit.app
- **问题反馈**: 使用应用内反馈功能
- **GitHub Issues**: [提交问题](https://github.com/your-username/LifeGit/issues)

## 🙏 致谢

感谢以下开源项目和服务：
- [SwiftUI](https://developer.apple.com/swiftui/) - Apple的声明式UI框架
- [SwiftData](https://developer.apple.com/documentation/swiftdata/) - Apple的数据持久化框架
- [Deepseek-R1](https://www.deepseek.com/) - AI任务规划服务
- [XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP) - 项目脚手架工具

## 📈 项目状态

- **当前版本**: v1.0.0
- **开发状态**: 活跃开发中
- **发布状态**: 准备发布
- **维护状态**: 积极维护

---

<div align="center">
  <p>用Git的方式管理人生，让每一天的努力都有迹可循</p>
  <p>Made with ❤️ by LifeGit Team</p>
</div>