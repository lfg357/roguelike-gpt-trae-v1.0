# 代码审查规范

> 本文件定义代码提交前的审查流程和检查清单，确保代码质量和项目稳定性。

---

## 1. 背景与目的

2026-07-14 发生类型推断错误（`Cannot infer the type of "in_hit_stop" variable`），导致工程无法打开。

**根本原因**：使用 `:=` 推断变量类型时，比较表达式的返回类型在 GDScript 中无法被正确推断。

**教训**：所有新增变量必须显式声明类型，禁止依赖类型推断。

---

## 2. 代码审查流程

```
代码修改 → 自检清单 → 语法检查 → 冒烟测试 → 提交/记录
```

### 2.1 自检阶段（修改完成后立即执行）

修改者必须逐项检查以下清单，全部通过后才能进入下一步。

### 2.2 语法检查

使用 Godot headless 模式进行完整项目解析：

```powershell
& "C:\Users\AdminLFG\AppData\Local\Programs\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tests/smoke_test.gd
```

要求：exit_code = 0，无 parse error。

### 2.3 冒烟测试

执行 `smoke_test.gd`，验证核心功能不被破坏。

要求：输出 `SMOKE_OK`，exit_code = 0。

---

## 3. 提交前检查清单

### 3.1 GDScript 语法规范

| # | 检查项 | 要求 | 严重程度 |
|---|--------|------|----------|
| 1 | 变量类型声明 | 所有变量必须显式声明类型，禁止使用 `:=` 依赖类型推断 | S |
| 2 | 函数返回类型 | 所有函数必须声明返回类型 `-> void / int / float / ...` | S |
| 3 | null 安全 | 访问字典/对象前必须检查是否为 null，使用 `get()` 安全访问 | A |
| 4 | 数组边界检查 | 数组访问前必须检查索引是否在有效范围内 | A |
| 5 | 信号参数匹配 | 信号连接的回调函数参数必须与信号定义完全一致 | S |
| 6 | 预加载资源 | preload 的资源路径必须正确，文件必须存在 | A |
| 7 | 缩进规范 | 使用 2 空格缩进，禁止混合制表符 | B |
| 8 | 命名规范 | 变量/函数使用 snake_case，常量使用 UPPER_CASE | B |

**严重程度说明**：
- S (Blocker)：会导致编译失败或游戏崩溃，必须修复
- A (Critical)：可能导致运行时错误或功能异常，必须修复
- B (Major)：影响代码可读性和可维护性，建议修复

### 3.2 架构与模块规范

| # | 检查项 | 要求 | 严重程度 |
|---|--------|------|----------|
| 1 | 模块继承 | 所有业务模块必须继承 RefCounted，禁止继承 Node | A |
| 2 | 信号使用 | 模块间通信必须通过 Main.gd 信号，不得直接互相调用 | B |
| 3 | null 保护 | 模块方法必须检查 main 和 main.player 是否为 null | A |
| 4 | 数据封装 | 模块不得直接修改其他模块的内部状态 | B |
| 5 | 边界检查 | 五行盘方法必须包含槽位边界检查，防止崩溃 | A |

### 3.3 功能完整性

| # | 检查项 | 要求 | 严重程度 |
|---|--------|------|----------|
| 1 | 状态机完整性 | 新增状态必须在所有状态切换处处理 | A |
| 2 | 错误处理 | 边界情况必须处理（空数组、null 值、除零等） | A |
| 3 | 资源清理 | 动态创建的 Node 必须正确释放（queue_free） | A |
| 4 | 事件清理 | 信号连接必须在适当时候断开（如有必要） | B |

### 3.4 性能与稳定性

| # | 检查项 | 要求 | 严重程度 |
|---|--------|------|----------|
| 1 | 死循环检查 | 循环必须有明确的退出条件 | S |
| 2 | 递归深度 | 递归必须有终止条件，避免栈溢出 | A |
| 3 | 内存泄漏 | Node 实例必须加入场景树或使用 RefCounted | A |
| 4 | 帧时间 | _process 中不得执行耗时操作（如大量计算、IO） | B |

### 3.5 配置与资源

| # | 检查项 | 要求 | 严重程度 |
|---|--------|------|----------|
| 1 | 资源路径 | 所有 preload / load 的资源路径必须正确 | S |
| 2 | 配置完整性 | 新增配置项必须有默认值和注释说明 | B |
| 3 | 版本兼容 | Godot API 使用必须兼容 4.7 stable | A |
| 4 | 平台兼容 | 代码必须兼容 Windows 平台 | B |

---

## 4. 常见陷阱与规避

### 4.1 类型推断陷阱

**错误写法**：
```gdscript
var in_hit_stop := combat_feedback_module.get_hit_stop_time() > 0.0  # ❌ 无法推断类型
```

**正确写法**：
```gdscript
var in_hit_stop: bool = combat_feedback_module.get_hit_stop_time() > 0.0  # ✅ 显式声明
```

**规则**：所有变量声明必须显式指定类型，禁止使用 `:=` 依赖类型推断。

### 4.2 字典访问陷阱

**错误写法**：
```gdscript
var value = player["nonexistent_key"]  # ❌ 键不存在会报错
```

**正确写法**：
```gdscript
var value = player.get("nonexistent_key", default_value)  # ✅ 安全访问
```

### 4.3 信号连接陷阱

**错误写法**：
```gdscript
some_signal.connect(my_callback)  # ❌ 参数不匹配
```

**正确做法**：
- 连接前检查信号定义和回调函数签名
- 确保参数数量、类型、顺序完全一致

### 4.4 节点生命周期陷阱

**错误做法**：
- 创建 Node 后不加入场景树，也不手动释放
- 在 `_ready()` 中引用未初始化的节点

**正确做法**：
- 动态创建的 Node 必须 `add_child()` 或及时 `queue_free()`
- 优先使用 RefCounted 管理数据对象

---

## 5. 验证命令清单

### 5.1 语法解析检查

```powershell
# 完整项目解析（会导入所有资源并检查语法）
& "C:\Users\AdminLFG\AppData\Local\Programs\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --quit
```

### 5.2 冒烟测试

```powershell
& "C:\Users\AdminLFG\AppData\Local\Programs\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tests/smoke_test.gd
```

### 5.3 动画深度测试

```powershell
& "C:\Users\AdminLFG\AppData\Local\Programs\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tests/animation_deep_test.gd
```

### 5.4 核心功能测试

```powershell
& "C:\Users\AdminLFG\AppData\Local\Programs\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tests/core_function_test.gd
```

### 5.5 回归测试

```powershell
& "C:\Users\AdminLFG\AppData\Local\Programs\Godot\Godot_v4.7-stable_win64_console.exe" --headless --path . --script res://tests/regression_test.gd
```

---

## 6. 修改分级与测试要求

| 修改级别 | 定义 | 必须执行的测试 |
|----------|------|----------------|
| 轻微修改 | 修改变量名、注释、文案等不影响逻辑的内容 | 语法解析检查 |
| 一般修改 | 修改单个函数的实现逻辑 | 语法解析 + 冒烟测试 |
| 重要修改 | 修改核心模块、新增功能、调整数据结构 | 语法解析 + 冒烟 + 核心功能测试 |
| 重大修改 | 架构调整、模块拆分、核心机制重构 | 全部测试 + 实机验收 |

---

## 7. 文档同步要求

代码修改完成后，必须同步更新以下文档：

| 修改类型 | 需要更新的文档 |
|----------|----------------|
| 任何代码修改 | CHANGELOG.md |
| 任何工程变更 | HANDOFF.md |
| 新增功能/模块 | TODO.md（标记进度）、CURRENT.md（更新状态） |
| 新增长期规则 | MEMORY.md |
| 新增设计决策 | DECISIONS.md |
| 新增测试用例 | TEST_CASES.md |

---

## 8. 审查记录

每次代码审查结果必须记录在案，格式如下：

```
日期：YYYY-MM-DD
修改内容：简要描述
审查人：AI / Human
审查结果：PASS / FAIL
问题列表：
  - 问题1（严重程度 S/A/B）：描述
  - 问题2（严重程度 S/A/B）：描述
修复状态：已修复 / 待修复
测试结果：
  - 语法解析：PASS / FAIL
  - 冒烟测试：PASS / FAIL
```

---

## 9. 附则

- 本规范自 2026-07-14 起生效
- 所有代码修改必须遵循本规范
- 如遇规范未覆盖的情况，应先补充规范再实施
- 规范更新须经用户确认
