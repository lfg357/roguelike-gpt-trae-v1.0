---
alwaysApply: false
description: 当 Agent 需要恢复项目状态、开始新任务、切换上下文、或进行自我审计时，使用本规则获取对应的 Prompt 模板。
---

# AI-POS Prompt 模板库（智能生效）

> 触发场景：项目恢复、新任务、上下文切换、自我审计。

---

## Recovery（项目恢复）

```
阅读：
- README.md
- ai-pos/CURRENT.md
- ai-pos/TODO.md
- ai-pos/DECISIONS.md

恢复项目状态并继续当前任务。

禁止：
- 重新介绍项目
- 重新规划架构
- 修改已确认 Decision
```

---

## New Task（新任务）

```
任务：{{Task}}

要求：
- 遵循 AGENTS.md
- 保持当前架构
- 更新 ai-pos/CURRENT.md（如需要）
- 完成后同步 ai-pos/TODO.md、ai-pos/CHANGELOG.md
```

---

## Context Handoff（上下文交接）

```
准备进行 Context Compression / 模型切换 / 会话结束。

## 项目当前状态
（从 ai-pos/CURRENT.md Recovery Snapshot 复制）

## 本轮已完成
- ...

## 本轮未完成
- ...

## 关键上下文（本轮临时信息）
- 当前讨论的核心问题：...
- 已尝试但失败的方案：...
- 用户最新偏好/指示：...

## 下一步
（从 CURRENT.md Next Action 复制）

## 恢复入口
按顺序阅读：README → ai-pos/CURRENT → ai-pos/DECISIONS → ai-pos/TODO
```

---

## Self-Audit（自我审计）

```
任务完成后逐条检查：

□ 是否阅读了所有必要文档？
□ 是否有输出来自模型默认知识而非项目文档？
□ 是否修改了项目文件？→ ai-pos/CHANGELOG 已同步？
□ 是否产生新长期规则？→ ai-pos/MEMORY 已同步？
□ 是否产生新设计决策？→ ai-pos/DECISIONS 已同步？
□ 是否更新了 ai-pos/CURRENT.md Recovery Snapshot？
□ 是否有 ⚠️ 或 ❓ 内容被写入文档？

任一项不通过 → 先修正再交付。
```

---

## Anti-Hallucination（防幻觉）

```
生成任何事实性内容前，先确认信息来源：

1. 信息来源是否为项目文档？
   → 是：引用具体文档及段落
   → 否：是否有搜索结果支撑？
     → 是：引用来源 URL
     → 否：标记为 ⚠️ 未确认，说明置信度

禁止：
- 凭模型默认知识生成未经验证的事实
- 将推测表述为确定事实
- 无文档支撑时修改项目文件
```

---

## Fabrication Prevention（编造预防）

```
每次准备写入项目文档前，逐条确认：

1. 要写入的内容来自哪里？
   □ 用户明确要求
   □ 项目已有文档
   □ 搜索结果（附 URL）
   □ 代码执行结果
   □ 以上都不是 → 🛑 停止写入

2. 这个修改会影响哪些文件？列出所有。

3. 是否有现存 Decision 或 Rule 与此冲突？
   检查 DECISIONS.md 和 MEMORY.md。

4. 用户是否确认了此修改？
   □ 是 → 写入
   □ 否 → 仅写草稿，标记 ⚠️ 待确认

全部通过后才允许写入。
```
