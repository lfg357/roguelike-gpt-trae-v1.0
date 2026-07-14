# trae-AI-POS — Trae 集成套件

> 将 AI-POS 泛用规范体系嵌入 Trae IDE，让 AI 自动遵守防幻觉、文档同步、状态管理等协议。

---

## 文件结构

```
trae-AI-POS/
├── AGENTS.md                     ← Trae 自动识别入口（每轮加载）
├── .trae/rules/
│   ├── ai-pos-core.md            ← 始终生效：防幻觉、不确定性标记、禁止行为
│   ├── ai-pos-workflow.md        ← 智能生效：工作流程、文档同步、恢复顺序
│   ├── ai-pos-prompts.md         ← 智能生效：Recovery 等 6 个 Prompt 模板
│   └── ai-pos-verify.md          ← 手动触发：完整验证协议
└── templates/
    ├── PROJECT.md                ← 填项目名即用
    ├── MEMORY.md                 ← 填长期偏好
    ├── CURRENT.md                ← 填当前状态
    ├── DECISIONS.md              ← 设计决策（空模板）
    ├── TODO.md                   ← 任务队列（空模板）
    └── CHANGELOG.md              ← 变更日志（空模板）
```

---

## 部署到新项目（3 步）

### Step 1：复制文件

将以下内容复制到目标项目根目录：
- `AGENTS.md`
- `.trae/`（整个目录）
- `ai-pos/`（整个目录）

### Step 2：填写项目信息

打开 `ai-pos/` 中的文件，替换所有 `【占位符】`：
- PROJECT.md：项目名称、负责人、背景、目标
- MEMORY.md：输出风格、代码规范、长期偏好
- CURRENT.md：项目状态 → Planning，填入当前阶段

### Step 3：在 Trae 中启用

Trae → 设置 → 规则 → 导入设置 → 开启「将 AGENTS.md 包含在上下文中」

---

## 生效方式

| 文件 | 何时生效 | 作用 |
|------|----------|------|
| AGENTS.md | 每轮对话自动加载 | Agent 身份、8 条原则、10 条禁止行为 |
| ai-pos-core.md | 始终生效 | 不确定性标记、来源标注、编造检测 |
| ai-pos-workflow.md | 执行任务时智能触发 | 7 阶段工作流、文档同步顺序 |
| ai-pos-prompts.md | 需要模板时智能触发 | Recovery、New Task、Context Handoff 等 |
| ai-pos-verify.md | 输入 `#Rule ai-pos-verify` | 写入前验证、编造检测、人机确认协议 |

---

## 日常使用

- 新会话 → Agent 自动读 CURRENT.md Recovery Snapshot（30 秒恢复）
- 执行任务 → 自动触发 ai-pos-workflow，强制文档同步
- 写入文档前 → `#Rule ai-pos-verify` 走完整验证
- 发现 AI 幻觉 → ai-pos-core 每轮生效，自动拦截

---

## 完整 AI-POS 规范

本套件是 AI-POS 的 Trae 精简版。完整 16 文件规范体系见：
`C:\Users\AdminLFG\Desktop\AI-POS\`

## 完整 AI-POS 规范

本套件是 AI-POS 的 Trae 精简版。完整 16 文件规范体系见：
`C:\Users\AdminLFG\Desktop\AI-POS\`
