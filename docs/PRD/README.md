# EhViewer 业务迁移 PRD — Task List

将 Android 端 280+ Java 文件（网络、解析、下载、图库、UI 等）逐模块用 ArkTS 重写并实现功能对等。

## Best Practice: Micro-Tasks

将大任务拆成微任务，任务越小 = 代码质量越高。

**Bad:** `- [ ] 实现用户认证`
**Good:**
```
- [x] 创建 User 数据模型（email + password 字段）
- [x] 添加密码哈希工具函数
- [x] 创建注册 API 接口
- [x] 创建登录 API 接口
- [x] 添加 Session/Token 生成
- [x] 创建登出接口
```

## 文档索引

| 文档 | 说明 | 对应模块 |
|------|------|----------|
| [00-总览与排期](./00-总览与排期.md) | 项目目标、范围、阶段划分、里程碑 | 全项目 |
| [01-基础层与依赖映射](./01-基础层与依赖映射.md) | 工具类、第三方库替代、基础设施 | hippo/util, network, database, 第三方 |
| [02-数据模型与客户端核心](./02-数据模型与客户端核心.md) | 数据模型、请求/解析、EhEngine | client/data, parser, exception, EhClient |
| [03-下载与图库模块](./03-下载与图库模块.md) | 下载管理、图库浏览、爬虫 | download, gallery, spider |
| [04-设置与偏好](./04-设置与偏好.md) | 设置项、偏好存储、各类 Preference | preference, Settings, EhDB |
| [05-UI与页面](./05-UI与页面.md) | 页面、场景、Activity/Fragment 对应 | ui/, scene |
| [06-公共组件与基础设施](./06-公共组件与基础设施.md) | 通用 UI 组件、应用基类、内容提供 | widget, app, content, scene, drawable 等 |
| [07-需求索引表](./07-需求索引表.md) | 全部任务 Checklist 汇总索引 | 全需求 |

## 使用方式

- **排期**：按 00 中的阶段顺序安排迭代，优先完成基础层与客户端核心，再做下载/图库与 UI。
- **任务执行**：各文档内的 `- [ ]` 任务按顺序逐条执行，完成后标记为 `- [x]`。
- **验收**：每份文档末尾有「验收标准」Checklist，用于功能对等验收。

## 参考源码

- Android 源码路径：`app/src/main/java/com/hippo/`
- Harmony 现有入口：`entry/src/main/ets/`（已有部分 model、client 占位）
