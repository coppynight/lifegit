# Requirements Document

## Introduction

人生Git是一款专为iOS平台设计的创新个人目标管理应用，将Git版本控制的概念应用到人生目标管理中。用户的人生被视为一个完整的Git项目，主线人生是master分支，每个新目标都可以创建独立的分支进行管理。通过分支、提交、合并请求等Git概念，用户可以系统化地管理自己的目标，跟踪进度，并最终将成功的目标合并到人生主干中。

核心理念包括：无心理负担的目标创建、灵活专注的分支切换、以及成长可视化的版本升级系统。

## MVP版本规划

### MVP核心功能

为了快速验证产品概念和用户需求，MVP版本将专注于最核心的功能：

**MVP 1.0 包含功能：**
1. **基础分支管理** - 创建、查看、切换目标分支
2. **简单提交系统** - 记录日常进展（仅支持文本提交）
3. **主干视图** - 展示人生主线和基本统计
4. **基础合并功能** - 完成目标后合并到主干
5. **本地数据存储** - 基本的数据持久化
6. **AI任务计划模块** - 创建分支时通过Deepseek-R1生成任务计划，支持用户手工修改

**MVP 1.0 暂不包含：**
- 日程计划模块（根据任务计划生成具体日程安排）
- 高级AI功能（复盘报告、进度建议、智能优化）
- 复杂的任务依赖关系管理
- 标签系统
- 详细统计分析
- iCloud同步
- 数据导出
- 智能首页逻辑

### MVP用户流程

1. **首次使用**: 用户打开应用，看到空的主干视图，引导创建第一个目标分支
2. **创建目标**: 用户输入目标名称和详细描述，AI通过Deepseek-R1生成结构化任务计划
3. **确认任务**: 用户查看AI生成的任务计划（包含日/周/月维度的任务安排），可以采用、修改或重新生成
4. **执行任务**: 用户开始执行任务，通过提交记录每日进展和任务完成情况
5. **跟踪进度**: 用户可以查看分支的任务完成状态、提交历史和基本进度
6. **完成目标**: 当所有任务完成后，用户将分支合并到主干
7. **查看成果**: 在主干视图中查看已完成的目标和整体进展

### MVP成功指标

- 用户能够成功创建并管理至少一个目标分支
- AI任务拆解成功率 > 90%（能够为用户目标生成合理的任务计划）
- 用户对AI生成任务计划的采用率 > 70%
- 用户平均每周至少创建3次提交
- 用户能够完成完整的目标创建→任务规划→进展记录→目标完成流程
- 应用启动时间 < 2秒，AI任务拆解响应时间 < 10秒

## Requirements

### MVP版本需求 (v1.0)

#### Requirement 1: 基础分支管理系统

**User Story:** 作为用户，我希望能够创建和管理目标分支，以便我可以系统化地组织和追踪不同的人生目标。

#### Acceptance Criteria

1. WHEN 用户打开应用 THEN 系统 SHALL 显示主干（Master Branch）作为默认视图
2. WHEN 用户创建新目标 THEN 系统 SHALL 创建独立的目标分支
3. WHEN 用户查看分支列表 THEN 系统 SHALL 显示所有分支的状态（进行中🔵、已完成✅、已废弃❌）
4. WHEN 用户切换分支 THEN 系统 SHALL 在2秒内完成切换并显示对应分支内容
5. WHEN 用户在分支间切换 THEN 系统 SHALL 保存当前分支的状态和进度
6. IF 分支处于进行中状态 THEN 系统 SHALL 显示基本进度信息和提交数量

#### Requirement 2: 基础提交系统

**User Story:** 作为用户，我希望能够记录我的日常进展和成就，以便追踪我在各个目标上的具体行动。

#### Acceptance Criteria

1. WHEN 用户在任何分支上 THEN 系统 SHALL 允许创建文本提交记录
2. WHEN 用户创建提交 THEN 系统 SHALL 支持基础文本输入和简单分类
3. WHEN 用户提交记录 THEN 系统 SHALL 自动记录提交时间和所属分支
4. WHEN 用户查看提交历史 THEN 系统 SHALL 以简单列表形式展示所有提交
5. IF 用户创建提交 THEN 系统 SHALL 在1秒内完成保存并更新界面

#### Requirement 3: 基础合并功能

**User Story:** 作为用户，我希望能够将完成的目标合并到主干，以便记录我的人生成长。

#### Acceptance Criteria

1. WHEN 用户完成目标 THEN 系统 SHALL 允许将分支标记为完成并合并到主干
2. WHEN 目标合并到主干 THEN 系统 SHALL 在主干中显示该目标的完成记录
3. WHEN 合并完成 THEN 系统 SHALL 更新主干的统计信息
4. IF 用户选择废弃分支 THEN 系统 SHALL 允许标记分支为已废弃状态

#### Requirement 4: 本地数据存储

**User Story:** 作为用户，我希望我的数据能够安全地保存在本地，以便离线使用应用。

#### Acceptance Criteria

1. WHEN 用户使用应用 THEN 系统 SHALL 将所有数据存储在本地设备上
2. WHEN 用户创建或修改数据 THEN 系统 SHALL 立即保存到本地存储
3. WHEN 应用重启 THEN 系统 SHALL 能够恢复用户的所有数据
4. IF 数据操作失败 THEN 系统 SHALL 提供基本的错误提示

#### Requirement 5: 基础AI任务拆解

**User Story:** 作为用户，我希望AI能够帮助我将目标拆解成结构化的任务计划，以便我能更清晰地知道如何按步骤实现目标。

#### Acceptance Criteria

1. WHEN 用户创建新分支 THEN 系统 SHALL 将目标信息发送给Deepseek-R1进行任务拆解
2. WHEN AI生成任务计划 THEN 系统 SHALL 根据目标复杂度生成适当数量的任务（不限制具体数量）
3. WHEN AI生成任务计划 THEN 系统 SHALL 支持按日、周、月的时间维度组织任务
4. WHEN AI生成任务建议 THEN 系统 SHALL 包含任务名称、详细描述、建议执行时间和预估时长
5. WHEN 用户查看任务计划 THEN 系统 SHALL 允许用户采用、修改或重新生成计划
6. WHEN AI处理任务拆解 THEN 系统 SHALL 在10秒内完成并显示结果
7. IF AI服务不可用 THEN 系统 SHALL 允许用户手动创建任务列表
8. WHEN 用户执行任务 THEN 系统 SHALL 允许标记任务为已完成状态并记录完成时间

**AI任务拆解示例：**
- 用户目标：练习公开演讲
- AI生成计划：为期3周的训练计划
  - 第1周：基础准备（每天20分钟）
    - 第1天：录制自我介绍视频，分析语言习惯
    - 第2天：练习基本发声和呼吸技巧
    - 第3天：准备1分钟即兴演讲话题
    - ...
  - 第2周：技能提升（每天20分钟）
  - 第3周：实战练习（每天20分钟）

#### Requirement 6: 基础用户界面

**User Story:** 作为iOS用户，我希望应用界面简洁易用且符合iOS设计规范，以便快速上手使用。

#### Acceptance Criteria

1. WHEN 应用启动 THEN 系统 SHALL 在2秒内完成加载
2. WHEN 用户操作界面 THEN 系统 SHALL 遵循Apple人机界面指引
3. WHEN 用户进行操作 THEN 系统 SHALL 在1秒内响应
4. WHEN 用户切换页面 THEN 系统 SHALL 提供基本的过渡动画
5. IF 用户进行交互 THEN 系统 SHALL 提供即时的视觉反馈

### 完整版本需求 (v2.0+)

#### Requirement 6: 高级AI智能助手

**User Story:** 作为用户，我希望AI能够提供更深入的分析和建议，以便我能更高效地实现目标。

#### Acceptance Criteria

1. WHEN AI生成任务计划 THEN 系统 SHALL 包含预计时长和任务间的依赖关系
2. WHEN 用户执行任务一段时间后 THEN AI SHALL 根据执行情况提供优化建议
3. WHEN 用户完成目标准备合并 THEN AI SHALL 自动生成详细的复盘报告
4. WHEN AI提供建议 THEN 系统 SHALL 包含时间管理建议和任务调整建议
5. WHEN 用户遇到困难 THEN AI SHALL 能够分析进度并提供解决方案建议
6. WHEN 用户查看历史数据 THEN AI SHALL 能够识别模式并提供个性化建议

#### Requirement 7: 高级版本管理

**User Story:** 作为用户，我希望能够看到我的人生版本升级，以便可视化我的成长历程。

#### Acceptance Criteria

1. WHEN 重要目标合并后 THEN 系统 SHALL 升级版本号（v1.0, v2.0等）
2. WHEN 目标合并到主干 THEN 系统 SHALL 在合并节点显示特殊视觉效果（发光、动画）
3. WHEN 用户查看版本历史 THEN 系统 SHALL 显示所有版本升级记录
4. WHEN 合并完成 THEN 系统 SHALL 自动生成AI复盘报告
5. IF 分支被废弃 THEN 系统 SHALL 也提供复盘分析

#### Requirement 8: 标签系统

**User Story:** 作为用户，我希望能够为重要的人生节点打标签，以便标记和回顾重要的里程碑。

#### Acceptance Criteria

1. WHEN 用户创建标签 THEN 系统 SHALL 支持六种类型：里程碑🎯、生日🎂、职业💼、感情💑、教育🎓、成就🏆
2. WHEN 用户打标签 THEN 系统 SHALL 允许关联版本升级
3. WHEN 用户查看标签 THEN 系统 SHALL 以时间线形式展示所有标签
4. WHEN 用户查看统计 THEN 系统 SHALL 提供标签统计分析
5. IF 标签创建成功 THEN 系统 SHALL 在主干时间线中特殊标记显示

#### Requirement 9: 高级提交系统

**User Story:** 作为用户，我希望能够创建不同类型的提交记录，以便更好地分类和管理我的进展。

#### Acceptance Criteria

1. WHEN 用户创建提交 THEN 系统 SHALL 支持四种类型：任务完成✅、学习记录📚、生活感悟🌟、里程碑🏆
2. WHEN 用户查看提交历史 THEN 系统 SHALL 以时间线形式展示所有提交
3. WHEN 用户筛选提交 THEN 系统 SHALL 支持按分支和类型进行筛选
4. WHEN 用户创建提交 THEN 系统 SHALL 支持富文本和媒体附件

#### Requirement 10: 高级用户界面和交互

**User Story:** 作为iOS用户，我希望应用界面提供丰富的交互体验，以便更高效地使用应用。

#### Acceptance Criteria

1. WHEN 用户切换页面 THEN 系统 SHALL 提供流畅的动画效果
2. WHEN 目标合并到主干 THEN 系统 SHALL 在合并节点显示特殊视觉效果（发光、动画）
3. WHEN 用户进行复杂操作 THEN 系统 SHALL 提供进度指示和反馈
4. WHEN 用户查看数据 THEN 系统 SHALL 提供交互式图表和可视化

#### Requirement 11: 数据同步和备份

**User Story:** 作为用户，我希望我的数据能够在多设备间同步并安全备份，以便保护我的人生记录不丢失。

#### Acceptance Criteria

1. WHEN 数据存储 THEN 系统 SHALL 对本地数据进行加密
2. WHEN 用户需要备份 THEN 系统 SHALL 支持iCloud备份功能
3. WHEN 用户需要导出 THEN 系统 SHALL 提供数据导出功能
4. WHEN 应用更新 THEN 系统 SHALL 保持数据完整性和向后兼容
5. WHEN 多设备使用 THEN 系统 SHALL 支持iCloud数据同步

#### Requirement 12: 统计分析功能

**User Story:** 作为用户，我希望能够查看我的目标完成情况和成长趋势，以便了解自己的进步状况。

#### Acceptance Criteria

1. WHEN 用户查看统计 THEN 系统 SHALL 显示总提交数、完成目标数、活跃分支数、标签数
2. WHEN 用户查看分析 THEN 系统 SHALL 提供提交频率图表和目标完成率
3. WHEN 用户查看趋势 THEN 系统 SHALL 显示分支活跃度和成长趋势分析
4. WHEN 统计数据更新 THEN 系统 SHALL 实时反映最新的用户活动
5. IF 用户查看个人中心 THEN 系统 SHALL 显示人生版本和完整统计数据

#### Requirement 13: 日程计划模块

**User Story:** 作为用户，我希望系统能够根据任务计划自动生成具体的日程安排，以便我能更好地管理时间和执行任务。

#### Acceptance Criteria

1. WHEN 用户确认任务计划后 THEN 系统 SHALL 自动根据任务计划生成日程安排
2. WHEN 系统生成日程安排 THEN 系统 SHALL 根据任务时间维度（日/周/月）安排具体的执行时间
3. WHEN 用户查看日程 THEN 系统 SHALL 支持按日期查看当日的具体安排
4. WHEN 用户需要调整 THEN 系统 SHALL 允许手工修改日程项的时间和日期
5. WHEN 用户完成日程项 THEN 系统 SHALL 允许标记为已完成并记录完成时间
6. WHEN 日程发生冲突 THEN 系统 SHALL 提供冲突提醒和调整建议

#### Requirement 14: 智能首页逻辑

**User Story:** 作为用户，我希望应用能够智能地显示最相关的内容，以便我能快速进入工作状态。

#### Acceptance Criteria

1. WHEN 用户有活跃分支时 THEN 系统 SHALL 默认显示最近活跃的分支
2. WHEN 用户无活跃分支时 THEN 系统 SHALL 默认显示主干
3. WHEN 用户刚完成合并时 THEN 系统 SHALL 显示主干以展示成果
4. WHEN 用户自定义首页 THEN 系统 SHALL 支持四种模式：上次查看页面、始终显示主干、最活跃分支、智能推荐
5. IF 用户设置了偏好 THEN 系统 SHALL 记住并应用用户的首页偏好设置