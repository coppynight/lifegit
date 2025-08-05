# 人生Git 代码审查指南

## 📋 代码审查检查清单

### 🏗️ 架构和设计

#### MVVM架构合规性
- [ ] View层只包含UI逻辑，不包含业务逻辑
- [ ] ViewModel正确使用@Published属性发布状态变化
- [ ] Model层数据模型定义清晰，关系正确
- [ ] 依赖注入正确实现，避免硬编码依赖

#### SwiftUI最佳实践
- [ ] 正确使用@State, @StateObject, @ObservedObject, @EnvironmentObject
- [ ] View结构合理，避免过深嵌套
- [ ] 自定义View可复用性良好
- [ ] 动画和过渡效果流畅自然

#### SwiftData使用规范
- [ ] @Model类正确定义，属性类型合适
- [ ] 关系映射正确 (@Relationship)
- [ ] 数据迁移策略考虑周全
- [ ] 查询操作高效，避免N+1问题

### 🔒 安全性检查

#### 数据安全
- [ ] 敏感数据正确加密存储
- [ ] API密钥不在代码中硬编码
- [ ] 用户输入正确验证和清理
- [ ] 本地数据访问权限控制

#### 网络安全
- [ ] HTTPS连接强制使用
- [ ] 证书验证正确实现
- [ ] 网络请求超时设置合理
- [ ] 错误信息不泄露敏感数据

### 🚀 性能优化

#### 内存管理
- [ ] 避免循环引用，正确使用weak/unowned
- [ ] 大对象及时释放
- [ ] 图片和资源懒加载
- [ ] 内存警告正确处理

#### 响应性能
- [ ] 主线程不执行耗时操作
- [ ] 异步操作正确使用async/await
- [ ] UI更新在主线程执行
- [ ] 长列表使用LazyVStack/LazyHStack

#### 网络性能
- [ ] 网络请求合并和缓存
- [ ] 重试机制合理实现
- [ ] 超时设置适当
- [ ] 离线模式支持

### 🧪 测试覆盖

#### 单元测试
- [ ] 业务逻辑核心方法有测试覆盖
- [ ] 边界条件和异常情况测试
- [ ] Mock对象正确使用
- [ ] 测试用例命名清晰

#### 集成测试
- [ ] 数据层和业务层集成测试
- [ ] AI服务集成测试
- [ ] 错误处理集成测试
- [ ] 端到端流程测试

### 📱 用户体验

#### 界面设计
- [ ] 遵循Apple人机界面指引
- [ ] 支持深色模式
- [ ] 动态字体支持
- [ ] 无障碍功能支持

#### 交互体验
- [ ] 加载状态清晰显示
- [ ] 错误信息用户友好
- [ ] 操作反馈及时
- [ ] 手势操作直观

#### 国际化
- [ ] 文本字符串可本地化
- [ ] 日期和数字格式本地化
- [ ] 布局适应不同语言
- [ ] 文化差异考虑

### 🔧 代码质量

#### 代码风格
- [ ] 遵循Swift编码规范
- [ ] 命名清晰有意义
- [ ] 注释充分且准确
- [ ] 代码格式一致

#### 代码结构
- [ ] 函数长度合理 (< 50行)
- [ ] 类和结构体职责单一
- [ ] 避免重复代码
- [ ] 依赖关系清晰

#### 错误处理
- [ ] 异常情况全面考虑
- [ ] 错误信息详细准确
- [ ] 恢复机制合理
- [ ] 日志记录完整

## 🔍 具体检查项目

### AI服务集成
```swift
// ✅ 正确的AI服务调用
class TaskPlanService {
    private let client: DeepseekR1Client
    private let errorHandler: AIServiceErrorHandler
    
    func generateTaskPlan(for branch: Branch) async throws -> TaskPlan {
        do {
            let response = try await client.generateCompletion(prompt: buildPrompt(for: branch))
            return try parseTaskPlan(from: response, branchId: branch.id)
        } catch {
            await errorHandler.handleError(error, context: "TaskPlanService.generateTaskPlan")
            throw error
        }
    }
}

// ❌ 错误的实现
class BadTaskPlanService {
    func generateTaskPlan(for branch: Branch) -> TaskPlan {
        // 同步调用异步API - 错误
        let response = try! client.generateCompletion(prompt: "...")
        return TaskPlan(...)
    }
}
```

### SwiftData模型定义
```swift
// ✅ 正确的模型定义
@Model
class Branch {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String
    var status: BranchStatus
    var createdAt: Date
    var progress: Double
    
    @Relationship(deleteRule: .cascade) var commits: [Commit]
    @Relationship(deleteRule: .cascade) var taskPlan: TaskPlan?
    @Relationship(inverse: \User.branches) var user: User?
    
    init(name: String, description: String) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.status = .active
        self.createdAt = Date()
        self.progress = 0.0
    }
}

// ❌ 错误的实现
@Model
class BadBranch {
    var id: String = UUID().uuidString // 应该使用UUID类型
    var name: String = "" // 应该在初始化时设置
    var commits: [Commit] = [] // 缺少@Relationship注解
}
```

### 错误处理
```swift
// ✅ 正确的错误处理
func createBranch(name: String, description: String) async throws -> Branch {
    guard !name.isEmpty else {
        throw ValidationError.emptyName
    }
    
    guard name.count <= 100 else {
        throw ValidationError.nameTooLong
    }
    
    do {
        let branch = Branch(name: name, description: description)
        let taskPlan = try await taskPlanService.generateTaskPlan(for: branch)
        branch.taskPlan = taskPlan
        
        try await repository.save(branch)
        return branch
    } catch let error as AIServiceError {
        // AI服务错误，提供降级方案
        let branch = Branch(name: name, description: description)
        branch.taskPlan = createManualTaskPlan(for: branch)
        try await repository.save(branch)
        return branch
    } catch {
        throw BranchCreationError.saveFailed(error)
    }
}

// ❌ 错误的实现
func badCreateBranch(name: String, description: String) -> Branch {
    let branch = Branch(name: name, description: description)
    try! repository.save(branch) // 强制解包 - 危险
    return branch
}
```

### UI状态管理
```swift
// ✅ 正确的状态管理
@MainActor
class BranchManager: ObservableObject {
    @Published var branches: [Branch] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadBranches() async {
        isLoading = true
        error = nil
        
        do {
            branches = try await repository.findAll()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

// ❌ 错误的实现
class BadBranchManager: ObservableObject {
    @Published var branches: [Branch] = []
    
    func loadBranches() {
        // 在主线程执行耗时操作 - 错误
        branches = try! repository.findAll()
    }
}
```

## 📊 代码质量指标

### 复杂度指标
- 圈复杂度 < 10
- 函数长度 < 50行
- 类长度 < 500行
- 嵌套深度 < 4层

### 测试指标
- 单元测试覆盖率 > 80%
- 集成测试覆盖率 > 60%
- 关键路径测试覆盖率 = 100%

### 性能指标
- 应用启动时间 < 2秒
- UI响应时间 < 1秒
- 内存使用 < 100MB
- 网络请求超时 < 30秒

## 🚨 常见问题和解决方案

### 内存泄漏
```swift
// ❌ 循环引用
class ViewController {
    var completion: (() -> Void)?
    
    func setupCompletion() {
        completion = {
            self.doSomething() // 强引用self
        }
    }
}

// ✅ 正确处理
class ViewController {
    var completion: (() -> Void)?
    
    func setupCompletion() {
        completion = { [weak self] in
            self?.doSomething()
        }
    }
}
```

### 线程安全
```swift
// ❌ 线程不安全
class DataManager {
    private var cache: [String: Any] = [:]
    
    func setValue(_ value: Any, forKey key: String) {
        cache[key] = value // 多线程访问不安全
    }
}

// ✅ 线程安全
actor DataManager {
    private var cache: [String: Any] = [:]
    
    func setValue(_ value: Any, forKey key: String) {
        cache[key] = value // Actor保证线程安全
    }
}
```

### 网络错误处理
```swift
// ❌ 简单粗暴
func fetchData() async throws -> Data {
    return try await URLSession.shared.data(from: url).0
}

// ✅ 完善的错误处理
func fetchData() async throws -> Data {
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        return data
    } catch {
        if error is URLError {
            throw NetworkError.connectionFailed
        }
        throw error
    }
}
```

## ✅ 审查通过标准

### 必须满足的条件
- [ ] 所有编译警告已解决
- [ ] 所有单元测试通过
- [ ] 代码覆盖率达标
- [ ] 性能指标满足要求
- [ ] 安全检查通过
- [ ] 用户体验测试通过

### 审查签字
- **代码审查员**: _________________ 日期: _________
- **技术负责人**: _________________ 日期: _________
- **架构师**: _________________ 日期: _________

## 📚 参考资源

### Apple官方文档
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata/)

### 最佳实践
- [iOS App Security Best Practices](https://developer.apple.com/documentation/security/)
- [Performance Best Practices](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance/)
- [Testing Best Practices](https://developer.apple.com/documentation/xctest/)