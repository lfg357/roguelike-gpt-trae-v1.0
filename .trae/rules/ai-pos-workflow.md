---
alwaysApply: false
description: 当 Agent 需要执行任务、同步文档、恢复项目状态或切换工作模块时，使用本规则获取完整工作流程和文档同步规范。
---

# AI-POS 工作流程（智能生效）

> 触发场景：执行任务、同步文档、恢复状态、模块切换。

---

## 工作总流程

```
接收任务 → 恢复项目 → 理解任务 → 制定计划 → 执行任务 → 验证结果 → 同步文档 → 等待下一任务
```

禁止跳过任何步骤。

---

## 项目恢复（Phase 2）

按顺序读取，恢复完成前不得修改任何文件：

```
README → ai-pos/PROJECT → ai-pos/MEMORY → ai-pos/CURRENT → ai-pos/DECISIONS → ai-pos/TODO
```

恢复信息：项目目标 → 当前阶段 → 当前任务 → 长期约束 → 历史决策 → 下一步。

---

## 文档同步（Phase 7）

任务完成后按此顺序同步：

| 顺序 | 文档 | 操作 |
|------|------|------|
| 1 | ai-pos/CURRENT | 更新当前工作位置 + Recovery Snapshot |
| 2 | ai-pos/TODO | 删除已完成任务，新增后续任务 |
| 3 | ai-pos/CHANGELOG | 记录本次修改，不得遗漏 |
| 4 | ai-pos/DECISIONS | 仅记录新的长期设计 |
| 5 | ai-pos/MEMORY | 仅记录新长期规则 |

---

## Context Compression 处理

```
停止工作 → 同步文档 → Compression → 重新读取文档 → 恢复状态 → 继续工作
```

禁止压缩后直接继续工作。

---

## 新会话恢复

1. 读取 ai-pos/CURRENT.md Recovery Snapshot（≤300 字，30 秒恢复）
2. 读取 ai-pos/DECISIONS.md 确认历史决策
3. 读取 ai-pos/TODO.md 确认待办
4. 如需深度恢复 → ai-pos/PROJECT + ai-pos/MEMORY

---

## 模块切换

结束当前模块 → 同步文档 → 恢复新模块状态 → 开始新模块。禁止多模块交叉执行。

---

## 任务完成检查

```
□ 任务目标全部完成？
□ CURRENT / TODO / CHANGELOG 三者状态一致？
□ Recovery Snapshot 是否最新？
□ 新设计决策 → DECISIONS 已更新？
□ 新长期规则 → MEMORY 已更新？
```
