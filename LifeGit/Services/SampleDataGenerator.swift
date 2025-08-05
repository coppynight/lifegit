import Foundation
import SwiftData

/// Service for generating sample data for development and testing
@MainActor
class SampleDataGenerator: ObservableObject {
    static let shared = SampleDataGenerator()
    
    private init() {}
    
    /// Generate comprehensive sample data for the app
    func generateSampleData() async {
        do {
            let dataManager = DataManager.shared
            let modelContext = dataManager.modelContext
            
            // Get or create default user
            let user = try dataManager.getDefaultUser()
            
            // Create sample branches with different types of goals
            let sampleBranches = createSampleBranches(for: user)
            
            for branch in sampleBranches {
                modelContext.insert(branch)
                
                // Create task plan for each branch
                if let taskPlan = createSampleTaskPlan(for: branch) {
                    modelContext.insert(taskPlan)
                    branch.taskPlan = taskPlan
                }
                
                // Create sample commits for some branches
                let commits = createSampleCommits(for: branch, user: user)
                for commit in commits {
                    modelContext.insert(commit)
                }
            }
            
            // Create some commits for master branch
            let masterBranch = try dataManager.getMasterBranch()
            let masterCommits = createMasterBranchCommits(for: masterBranch, user: user)
            for commit in masterCommits {
                modelContext.insert(commit)
            }
            
            try dataManager.save()
            
            print("✅ 示例数据生成完成")
            
        } catch {
            print("❌ 示例数据生成失败: \(error)")
        }
    }
    
    /// Create sample branches with different goal types
    private func createSampleBranches(for user: User) -> [Branch] {
        let branchTemplates: [(name: String, branchDescription: String, status: BranchStatus, progress: Double, daysAgo: Int)] = [
            (
                name: "学习SwiftUI",
                branchDescription: "掌握SwiftUI开发技能，能够独立开发iOS应用",
                status: .active,
                progress: 0.6,
                daysAgo: 15
            ),
            (
                name: "每日晨跑习惯",
                branchDescription: "养成每天早上跑步30分钟的习惯，提升身体素质",
                status: .active,
                progress: 0.8,
                daysAgo: 30
            ),
            (
                name: "阅读《深度工作》",
                branchDescription: "认真阅读并实践《深度工作》一书的理念和方法",
                status: .completed,
                progress: 1.0,
                daysAgo: 45
            ),
            (
                name: "学习日语",
                branchDescription: "学习日语基础语法和常用词汇，达到N4水平",
                status: .active,
                progress: 0.3,
                daysAgo: 60
            ),
            (
                name: "减重10公斤",
                branchDescription: "通过合理饮食和运动，在3个月内健康减重10公斤",
                status: .abandoned,
                progress: 0.2,
                daysAgo: 90
            )
        ]
        
        return branchTemplates.map { template in
            let createdAt = Calendar.current.date(byAdding: .day, value: -template.daysAgo, to: Date()) ?? Date()
            let completedAt = template.status == .completed ? Date() : nil
            
            let branch = Branch(
                name: template.name,
                branchDescription: template.branchDescription,
                status: template.status,
                createdAt: createdAt,
                progress: template.progress
            )
            branch.completedAt = completedAt
            branch.user = user
            return branch
        }
    }
    
    /// Create sample task plan for a branch
    private func createSampleTaskPlan(for branch: Branch) -> TaskPlan? {
        let taskPlan = TaskPlan(
            branchId: branch.id,
            totalDuration: getSampleTotalDuration(for: branch.name),
            createdAt: branch.createdAt,
            isAIGenerated: true
        )
        
        let tasks = createSampleTasks(for: branch, taskPlan: taskPlan)
        taskPlan.tasks = tasks
        
        return taskPlan
    }
    
    /// Get sample total duration based on branch name
    private func getSampleTotalDuration(for branchName: String) -> String {
        switch branchName {
        case "学习SwiftUI":
            return "6-8周"
        case "每日晨跑习惯":
            return "21天习惯养成"
        case "阅读《深度工作》":
            return "2-3周"
        case "学习日语":
            return "3-6个月"
        case "减重10公斤":
            return "3个月"
        default:
            return "4-6周"
        }
    }
    
    /// Create sample tasks for different branch types
    private func createSampleTasks(for branch: Branch, taskPlan: TaskPlan) -> [TaskItem] {
        switch branch.name {
        case "学习SwiftUI":
            return createSwiftUILearningTasks(taskPlan: taskPlan, branch: branch)
        case "每日晨跑习惯":
            return createRunningHabitTasks(taskPlan: taskPlan, branch: branch)
        case "阅读《深度工作》":
            return createReadingTasks(taskPlan: taskPlan, branch: branch)
        case "学习日语":
            return createJapaneseLearningTasks(taskPlan: taskPlan, branch: branch)
        case "减重10公斤":
            return createWeightLossTasks(taskPlan: taskPlan, branch: branch)
        default:
            return []
        }
    }
    
    /// Create SwiftUI learning tasks
    private func createSwiftUILearningTasks(taskPlan: TaskPlan, branch: Branch) -> [TaskItem] {
        let taskData: [(title: String, description: String, duration: Int, scope: TaskTimeScope, completed: Bool)] = [
            ("安装Xcode和设置开发环境", "下载安装Xcode，创建第一个SwiftUI项目", 60, .daily, true),
            ("学习SwiftUI基础语法", "掌握View、State、Binding等基本概念", 120, .daily, true),
            ("实践布局和导航", "学习VStack、HStack、NavigationView等布局组件", 90, .daily, true),
            ("数据绑定和状态管理", "深入理解@State、@Binding、@ObservedObject", 120, .daily, true),
            ("网络请求和数据处理", "学习URLSession和JSON解析", 150, .weekly, false),
            ("动画和过渡效果", "掌握SwiftUI动画系统", 90, .weekly, false),
            ("完成一个完整项目", "独立开发一个包含多个页面的应用", 300, .weekly, false)
        ]
        
        return taskData.enumerated().map { index, data in
            let task = TaskItem(
                title: data.title,
                taskDescription: data.description,
                estimatedDuration: data.duration,
                timeScope: data.scope,
                isAIGenerated: true,
                orderIndex: index,
                isCompleted: data.completed,
                createdAt: branch.createdAt
            )
            task.taskPlan = taskPlan
            if data.completed {
                task.completedAt = Calendar.current.date(byAdding: .day, value: -(taskData.count - index), to: Date())
            }
            return task
        }
    }
    
    /// Create running habit tasks
    private func createRunningHabitTasks(taskPlan: TaskPlan, branch: Branch) -> [TaskItem] {
        let taskData: [(title: String, description: String, duration: Int, scope: TaskTimeScope, completed: Bool)] = [
            ("准备跑步装备", "购买合适的跑鞋和运动服装", 30, .daily, true),
            ("制定跑步计划", "设定每周跑步频率和距离目标", 20, .daily, true),
            ("第一周：适应期", "每天跑步15-20分钟，重点是养成习惯", 20, .weekly, true),
            ("第二周：增加强度", "逐步增加到25-30分钟", 25, .weekly, true),
            ("第三周：稳定期", "保持30分钟跑步，关注跑步姿势", 30, .weekly, false),
            ("记录跑步数据", "使用运动APP记录距离、时间和心率", 10, .daily, true)
        ]
        
        return taskData.enumerated().map { index, data in
            let task = TaskItem(
                title: data.title,
                taskDescription: data.description,
                estimatedDuration: data.duration,
                timeScope: data.scope,
                isAIGenerated: true,
                orderIndex: index,
                isCompleted: data.completed,
                createdAt: branch.createdAt
            )
            task.taskPlan = taskPlan
            if data.completed {
                task.completedAt = Calendar.current.date(byAdding: .day, value: -(taskData.count - index), to: Date())
            }
            return task
        }
    }
    
    /// Create reading tasks
    private func createReadingTasks(taskPlan: TaskPlan, branch: Branch) -> [TaskItem] {
        let taskData: [(title: String, description: String, duration: Int, scope: TaskTimeScope, completed: Bool)] = [
            ("购买或借阅书籍", "获取《深度工作》纸质版或电子版", 15, .daily, true),
            ("阅读第一部分：理论基础", "理解深度工作的概念和重要性", 120, .weekly, true),
            ("阅读第二部分：实践方法", "学习具体的深度工作技巧", 120, .weekly, true),
            ("制定个人深度工作计划", "根据书中方法制定适合自己的计划", 60, .daily, true),
            ("实践深度工作一周", "按照计划实践深度工作方法", 300, .weekly, true),
            ("总结和反思", "写下读书心得和实践体会", 60, .daily, true)
        ]
        
        return taskData.enumerated().map { index, data in
            let task = TaskItem(
                title: data.title,
                taskDescription: data.description,
                estimatedDuration: data.duration,
                timeScope: data.scope,
                isAIGenerated: true,
                orderIndex: index,
                isCompleted: data.completed,
                createdAt: branch.createdAt
            )
            task.taskPlan = taskPlan
            if data.completed {
                task.completedAt = Calendar.current.date(byAdding: .day, value: -(taskData.count - index), to: Date())
            }
            return task
        }
    }
    
    /// Create Japanese learning tasks
    private func createJapaneseLearningTasks(taskPlan: TaskPlan, branch: Branch) -> [TaskItem] {
        let taskData: [(title: String, description: String, duration: Int, scope: TaskTimeScope, completed: Bool)] = [
            ("学习平假名", "掌握所有平假名的读音和写法", 180, .weekly, true),
            ("学习片假名", "掌握所有片假名的读音和写法", 180, .weekly, false),
            ("基础语法入门", "学习基本句型和语法规则", 240, .monthly, false),
            ("常用词汇积累", "每天学习20个新单词", 30, .daily, true),
            ("听力练习", "每天听日语音频30分钟", 30, .daily, false),
            ("口语练习", "跟读和模仿日语发音", 30, .daily, false)
        ]
        
        return taskData.enumerated().map { index, data in
            let task = TaskItem(
                title: data.title,
                taskDescription: data.description,
                estimatedDuration: data.duration,
                timeScope: data.scope,
                isAIGenerated: true,
                orderIndex: index,
                isCompleted: data.completed,
                createdAt: branch.createdAt
            )
            task.taskPlan = taskPlan
            if data.completed {
                task.completedAt = Calendar.current.date(byAdding: .day, value: -(taskData.count - index), to: Date())
            }
            return task
        }
    }
    
    /// Create weight loss tasks
    private func createWeightLossTasks(taskPlan: TaskPlan, branch: Branch) -> [TaskItem] {
        let taskData: [(title: String, description: String, duration: Int, scope: TaskTimeScope, completed: Bool)] = [
            ("制定饮食计划", "咨询营养师，制定健康的饮食方案", 90, .daily, true),
            ("购买体重秤", "选择精准的体重秤，每天记录体重", 30, .daily, true),
            ("第一月：适应期", "逐步调整饮食习惯，轻度运动", 60, .monthly, false),
            ("第二月：加强期", "增加运动强度，严格控制饮食", 90, .monthly, false),
            ("第三月：冲刺期", "最后冲刺，达到目标体重", 90, .monthly, false),
            ("每周体重记录", "记录体重变化和身体感受", 15, .weekly, true)
        ]
        
        return taskData.enumerated().map { index, data in
            let task = TaskItem(
                title: data.title,
                taskDescription: data.description,
                estimatedDuration: data.duration,
                timeScope: data.scope,
                isAIGenerated: true,
                orderIndex: index,
                isCompleted: data.completed,
                createdAt: branch.createdAt
            )
            task.taskPlan = taskPlan
            if data.completed {
                task.completedAt = Calendar.current.date(byAdding: .day, value: -(taskData.count - index), to: Date())
            }
            return task
        }
    }
    
    /// Create sample commits for branches
    private func createSampleCommits(for branch: Branch, user: User) -> [Commit] {
        var commits: [Commit] = []
        
        // Create different types of commits based on branch status and progress
        let commitCount = Int(branch.progress * 10) + 2 // 2-12 commits based on progress
        
        for i in 0..<commitCount {
            let daysAgo = commitCount - i
            let timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            
            let commitType = getRandomCommitType(for: branch, index: i)
            let message = generateCommitMessage(for: branch, type: commitType, index: i)
            
            let commit = Commit(
                message: message,
                type: commitType,
                timestamp: timestamp,
                branchId: branch.id
            )
            commit.branch = branch
            commit.user = user
            
            commits.append(commit)
        }
        
        return commits
    }
    
    /// Create commits for master branch
    private func createMasterBranchCommits(for masterBranch: Branch, user: User) -> [Commit] {
        let masterCommits: [(message: String, type: CommitType, daysAgo: Int)] = [
            ("完成《深度工作》阅读目标，提升专注力", .milestone, 5),
            ("建立晨跑习惯，身体素质明显改善", .milestone, 15),
            ("学会SwiftUI基础开发，可以独立创建简单应用", .milestone, 30),
            ("开始使用人生Git管理目标，生活更有条理", .reflection, 60)
        ]
        
        return masterCommits.map { data in
            let timestamp = Calendar.current.date(byAdding: .day, value: -data.daysAgo, to: Date()) ?? Date()
            let commit = Commit(
                message: data.message,
                type: data.type,
                timestamp: timestamp,
                branchId: masterBranch.id
            )
            commit.branch = masterBranch
            commit.user = user
            return commit
        }
    }
    
    /// Get random commit type based on branch and index
    private func getRandomCommitType(for branch: Branch, index: Int) -> CommitType {
        // First and last commits are more likely to be milestones
        if index == 0 || (branch.status == .completed && index > 5) {
            return Bool.random() ? .milestone : .taskComplete
        }
        
        // Random distribution for other commits
        let types: [CommitType] = [.taskComplete, .learning, .reflection, .milestone]
        let weights = [0.5, 0.25, 0.15, 0.1] // taskComplete is most common
        
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if random <= cumulative {
                return types[index]
            }
        }
        
        return .taskComplete
    }
    
    /// Generate commit message based on branch and type
    private func generateCommitMessage(for branch: Branch, type: CommitType, index: Int) -> String {
        switch branch.name {
        case "学习SwiftUI":
            return generateSwiftUICommitMessage(type: type, index: index)
        case "每日晨跑习惯":
            return generateRunningCommitMessage(type: type, index: index)
        case "阅读《深度工作》":
            return generateReadingCommitMessage(type: type, index: index)
        case "学习日语":
            return generateJapaneseCommitMessage(type: type, index: index)
        case "减重10公斤":
            return generateWeightLossCommitMessage(type: type, index: index)
        default:
            return generateGenericCommitMessage(type: type, index: index)
        }
    }
    
    private func generateSwiftUICommitMessage(type: CommitType, index: Int) -> String {
        let messages: [CommitType: [String]] = [
            .taskComplete: [
                "完成Xcode环境搭建",
                "学习完SwiftUI基础语法",
                "掌握VStack和HStack布局",
                "实现简单的导航功能",
                "完成数据绑定练习"
            ],
            .learning: [
                "理解了SwiftUI的声明式编程思想",
                "学习了@State和@Binding的区别",
                "掌握了NavigationView的使用方法",
                "了解了SwiftUI的生命周期"
            ],
            .reflection: [
                "SwiftUI比UIKit更直观易懂",
                "声明式编程让UI开发变得简单",
                "需要多练习才能熟练掌握"
            ],
            .milestone: [
                "成功创建第一个SwiftUI应用",
                "完成SwiftUI基础学习阶段",
                "能够独立开发简单的iOS应用"
            ]
        ]
        
        let typeMessages = messages[type] ?? ["完成今日学习任务"]
        return typeMessages.randomElement() ?? "完成今日学习任务"
    }
    
    private func generateRunningCommitMessage(type: CommitType, index: Int) -> String {
        let messages: [CommitType: [String]] = [
            .taskComplete: [
                "完成30分钟晨跑",
                "今日跑步3公里",
                "坚持晨跑第\(index + 1)天",
                "完成今日运动目标"
            ],
            .learning: [
                "学习了正确的跑步姿势",
                "了解了跑步前热身的重要性",
                "掌握了呼吸节奏技巧"
            ],
            .reflection: [
                "晨跑让我一天都充满活力",
                "坚持运动真的能改善心情",
                "身体素质明显提升了"
            ],
            .milestone: [
                "连续跑步一周达成",
                "晨跑习惯初步养成",
                "跑步距离突破5公里"
            ]
        ]
        
        let typeMessages = messages[type] ?? ["完成今日跑步"]
        return typeMessages.randomElement() ?? "完成今日跑步"
    }
    
    private func generateReadingCommitMessage(type: CommitType, index: Int) -> String {
        let messages: [CommitType: [String]] = [
            .taskComplete: [
                "阅读《深度工作》第\(index + 1)章",
                "完成今日阅读计划",
                "整理读书笔记",
                "完成章节总结"
            ],
            .learning: [
                "理解了深度工作的核心概念",
                "学习了专注力训练方法",
                "掌握了时间管理技巧"
            ],
            .reflection: [
                "深度工作确实能提高效率",
                "需要减少社交媒体的干扰",
                "专注是现代社会的稀缺能力"
            ],
            .milestone: [
                "完成《深度工作》全书阅读",
                "制定了个人深度工作计划",
                "开始实践深度工作方法"
            ]
        ]
        
        let typeMessages = messages[type] ?? ["完成今日阅读"]
        return typeMessages.randomElement() ?? "完成今日阅读"
    }
    
    private func generateJapaneseCommitMessage(type: CommitType, index: Int) -> String {
        let messages: [CommitType: [String]] = [
            .taskComplete: [
                "学习20个新单词",
                "完成平假名练习",
                "听力练习30分钟",
                "完成语法练习题"
            ],
            .learning: [
                "掌握了基本的问候语",
                "理解了日语的语序规则",
                "学会了数字的表达方法"
            ],
            .reflection: [
                "日语学习需要持续的练习",
                "听力是最大的挑战",
                "语法比想象中复杂"
            ],
            .milestone: [
                "完成平假名学习",
                "掌握100个常用单词",
                "能进行简单的日常对话"
            ]
        ]
        
        let typeMessages = messages[type] ?? ["完成今日日语学习"]
        return typeMessages.randomElement() ?? "完成今日日语学习"
    }
    
    private func generateWeightLossCommitMessage(type: CommitType, index: Int) -> String {
        let messages: [CommitType: [String]] = [
            .taskComplete: [
                "完成今日运动计划",
                "严格控制饮食摄入",
                "记录今日体重变化",
                "完成有氧运动45分钟"
            ],
            .learning: [
                "了解了健康饮食的重要性",
                "学习了基础代谢的概念",
                "掌握了卡路里计算方法"
            ],
            .reflection: [
                "减重需要坚持和耐心",
                "健康比体重数字更重要",
                "生活习惯的改变是关键"
            ],
            .milestone: [
                "体重下降2公斤",
                "腰围减少3厘米",
                "建立了健康的生活习惯"
            ]
        ]
        
        let typeMessages = messages[type] ?? ["完成今日减重计划"]
        return typeMessages.randomElement() ?? "完成今日减重计划"
    }
    
    private func generateGenericCommitMessage(type: CommitType, index: Int) -> String {
        let messages: [CommitType: [String]] = [
            .taskComplete: ["完成今日任务", "达成阶段目标", "按计划执行"],
            .learning: ["学到新知识", "获得新技能", "理解新概念"],
            .reflection: ["今日感悟", "经验总结", "思考收获"],
            .milestone: ["重要进展", "阶段性成果", "里程碑达成"]
        ]
        
        let typeMessages = messages[type] ?? ["完成任务"]
        return typeMessages.randomElement() ?? "完成任务"
    }
}

/// Development-only sample data generator for testing
extension SampleDataGenerator {
    /// Generate minimal sample data for quick testing
    func generateMinimalSampleData() async {
        do {
            let dataManager = DataManager.shared
            let modelContext = dataManager.modelContext
            
            let user = try dataManager.getDefaultUser()
            
            // Create one simple active branch
            let testBranch = Branch(
                name: "测试目标",
                branchDescription: "这是一个用于测试的示例目标",
                status: .active,
                progress: 0.3
            )
            testBranch.user = user
            modelContext.insert(testBranch)
            
            // Create simple task plan
            let taskPlan = TaskPlan(
                branchId: testBranch.id,
                totalDuration: "2周",
                isAIGenerated: false
            )
            
            let tasks = [
                TaskItem(title: "任务1", taskDescription: "第一个测试任务", estimatedDuration: 30, timeScope: .daily, orderIndex: 0, isCompleted: true),
                TaskItem(title: "任务2", taskDescription: "第二个测试任务", estimatedDuration: 60, timeScope: .daily, orderIndex: 1),
                TaskItem(title: "任务3", taskDescription: "第三个测试任务", estimatedDuration: 45, timeScope: .weekly, orderIndex: 2)
            ]
            
            for task in tasks {
                task.taskPlan = taskPlan
                modelContext.insert(task)
            }
            
            taskPlan.tasks = tasks
            testBranch.taskPlan = taskPlan
            modelContext.insert(taskPlan)
            
            try dataManager.save()
            
            print("✅ 最小示例数据生成完成")
            
        } catch {
            print("❌ 最小示例数据生成失败: \(error)")
        }
    }
}