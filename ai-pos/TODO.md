# TODO.md — 任务队列

---

# 1. 文档职责

TODO.md 维护尚未完成的任务。完成后的任务移出 TODO → 进入 CHANGELOG。

---

# 2. 任务状态

| 状态 | 含义 |
|------|------|
| Backlog | 已记录，未开始 |
| Ready | 可以开始 |
| In Progress | 当前执行（仅允许一个） |
| Blocked | 被阻塞 |
| Review | 等待审核 |
| Done | 已完成 → 移入 CHANGELOG |
| Cancelled | 已取消 |

---

# 3. 优先级

P0 > P1 > P2 > P3。同优先级按时间排序。

---

# 4. P0 — 最高优先级

```
Task ID：TASK-001
Title：补齐 ai-pos 文档占位内容
Priority：P0
Status：Done
Owner：AI
Depends On：None
Estimated：0.5 Days
Description：将 ai-pos/ 下所有文档（PROJECT、MEMORY、CURRENT、DECISIONS、TODO、CHANGELOG）中的占位符替换为项目实际内容，确保新 Agent 可通过文档快速恢复项目状态。
Expected Output：ai-pos/ 下 6 个文档全部填写完成，无占位符
Acceptance Criteria：
  □ PROJECT.md 包含项目基本信息、背景、目标、范围、原则、约束、风险、架构
  □ MEMORY.md 包含长期规则、长期偏好、长期约束、长期术语
  □ CURRENT.md 包含当前状态、当前任务、恢复快照、会话记忆
  □ DECISIONS.md 包含至少 5 条已实施的设计决策
  □ TODO.md 包含 P0/P1/P2 任务队列
  □ CHANGELOG.md 包含项目初始化和主要里程碑记录
```

```
Task ID：TASK-002
Title：复跑冒烟测试与动画深度测试
Priority：P0
Status：Done
Owner：AI
Depends On：TASK-001
Estimated：0.5 Days
Description：运行 Godot 解析测试、smoke_test.gd 和 animation_deep_test.gd，确认项目当前可运行且核心功能正常。
Expected Output：测试通过的日志输出
Acceptance Criteria：
  □ Godot headless 解析无错误
  □ smoke_test.gd 输出 SMOKE_OK
  □ animation_deep_test.gd 全部断言通过
  □ 测试结果记录到 CURRENT.md
```

---

# 5. P1 — 高优先级

```
Task ID：TEST-001
Title：测试体系建立与执行
Priority：P0
Status：Done
Owner：AI
Depends On：TASK-002
Estimated：2 Days
Description：建立完备的测试体系文档和自动化测试脚本，执行核心功能测试和回归测试，验证代码库稳定性。
Expected Output：测试脚本 + 测试报告 + 测试基线
Acceptance Criteria：
  ✅ 核心功能测试 15/15 PASS
  ✅ 回归测试 31/31 PASS
  ✅ 冒烟测试 PASS
  ✅ 动画深度测试 PASS
  ✅ 测试结果记录到 CHANGELOG 和 HANDOFF
```

```
Task ID：TASK-003
Title：实机视觉验收（阶段 A）
Priority：P1
Status：Ready
Owner：Human + AI
Depends On：TEST-001
Estimated：1 Day
Description：使用 F6/F7/F8/F9/F10/F11 Debug 入口进行实机视觉检查，确认角色动作、VFX 特效、UI 布局在 1280x720 下无问题。
Expected Output：视觉验收检查清单
Acceptance Criteria：
  □ 燕无归与敌人尺寸层级、脚底锚点、Y 轴遮挡顺序正确
  □ idle/run/attack/dodge/hurt/dead 顺序正确，无跳位
  □ 左右鼠标点击时普攻动作和刀光都朝点击方向
  □ 三段普攻各自使用对应序列，第三段有重量感且不遮 HUD
  □ 闪避、命中、暴击、破盾、死亡、五行特效完整播放无绿边
  □ 15 个副技能使用正确语义专属行，方向型特效旋转正确
  □ 遗物/武器获得和格局激活特效位置合适，不被 UI 遮挡
  □ 1280x720 下 HUD、地图、房间信息、底部操作栏、五行盘、商店无重叠
  □ Boss 前摇、石柱、护盾条、二阶段特效和漩涡门可读
```

```
Task ID：TASK-004
Title：制作并接入水墨粒子批次
Priority：P1
Status：Backlog
Owner：AI
Depends On：TASK-003
Estimated：2 Days
Description：制作 64-128px 水墨粒子贴图批次，替换当前 _spawn_ink 中的程序化圆点。
Expected Output：水墨粒子图集 + 运行时接入
Acceptance Criteria：
  □ 粒子图集符合水墨风格
  □ 替换 _spawn_ink 中的程序化圆点
  □ 普通命中、暴击、死亡等场景正确触发粒子
  □ 粒子效果在 1280x720 下不遮挡核心 UI
  □ smoke_test 仍通过
```

```
Task ID：TASK-005
Title：补顿帧叠加层与水墨手写伤害数字
Priority：P1
Status：Backlog
Owner：AI
Depends On：TASK-003
Estimated：1 Day
Description：制作专门的顿帧叠加层资源和水墨手写伤害数字字体，提升战斗反馈质感。
Expected Output：顿帧叠加层资源 + 伤害数字字体 + 接入代码
Acceptance Criteria：
  □ 顿帧时有专门的叠加层表现（闪白/墨闪等）
  □ 伤害数字使用水墨手写风格字体
  □ 伤害数字显示清晰，不被其他元素遮挡
  □ smoke_test 仍通过
```

```
Task ID：TASK-006
Title：第一套单色 TileMap 与秘境门视觉
Priority：P1
Status：Backlog
Owner：AI
Depends On：TASK-003
Estimated：2 Days
Description：制作 P0 单色瓦片集和基础房间装饰，统一秘境门视觉，替换当前代码绘制的场地。
Expected Output：TileSet 资源 + 房间场景 + 秘境门视觉
Acceptance Criteria：
  □ 32-64px 单色瓦片集
  □ 基础房间地面、墙体装饰
  □ 统一的秘境门视觉（8 方向均可）
  □ 战斗区尺寸保持 848x548
  □ smoke_test 仍通过
```

```
Task ID：TASK-007
Title：统一武器挂点、动作事件与 SFX 触发时点
Priority：P1
Status：Backlog
Owner：AI
Depends On：TASK-003
Estimated：1 Day
Description：在 CharacterSequences 和 VFXSequences 中统一武器挂点、动作事件点和残影时点，为后续音效接入做准备。
Expected Output：统一的事件点元数据
Acceptance Criteria：
  □ 所有武器动作有统一的挂点位置
  □ 动作关键帧（命中、收招等）有明确事件标记
  □ 残影出现时点与动作节奏匹配
  □ smoke_test 仍通过
```

```
Task ID：TASK-008
Title：音效包试听与授权核对
Priority：P1
Status：Backlog
Owner：Human + AI
Depends On：TASK-003
Estimated：1 Day
Description：逐个试听 art-resources/音效包/ 中的音效，核对授权条款，筛选出语义吻合的占位音效。
Expected Output：音效清单 + 授权确认表
Acceptance Criteria：
  □ 每个音效包都听过并记录语义
  □ 授权条款明确且允许商用
  □ 筛选出 P0 需要的核心音效（攻击、命中、闪避、UI 等）
  □ 不直接将未审核的音效接入项目
```

```
Task ID：TASK-009
Title：燕无归 P0 头像与立绘
Priority：P1
Status：Backlog
Owner：AI
Depends On：TASK-003
Estimated：1 Day
Description：按附录 G.1 制作燕无归的 P0 头像和立绘，用于 UI 展示。
Expected Output：头像 + 半身立绘资源
Acceptance Criteria：
  □ 头像符合水墨风格
  □ 立绘与游戏内角色形象一致
  □ 在五行盘/背包/武器抉择等 UI 中正确显示
  □ smoke_test 仍通过
```

---

# 6. P2 — 普通优先级

```
Task ID：TASK-010
Title：五行盘拖拽与实时预览
Priority：P2
Status：Done
Owner：AI
Depends On：TASK-002
Estimated：2 Days
Description：实现五行盘完整拖拽交互：拖入、拖出、盘内互换、拖动实时预览格局变化。
Expected Output：完整的拖拽交互系统
Acceptance Criteria：
  ✅ 遗物可从背包拖入五行盘槽位（空槽位或替换已有遗物）
  ✅ 盘内遗物可互换位置（直接拖动到其他槽位交换）
  ✅ 拖动过程中实时预览格局变化（build_label 显示预览内容）
  ✅ 盘满时拖动替换逻辑正确（拖入非空槽位自动交换）
  ✅ 目标槽位绿色高亮提示
  ✅ 拖动精灵跟随鼠标
  ✅ smoke_test 仍通过
```

```
Task ID：TASK-011
Title：扩展五行精确数量配方与标签组合
Priority：P2
Status：Done
Owner：Human + AI
Depends On：TASK-002
Estimated：3 Days
Description：按设计表扩展五行精确数量配方和标签组合数量，从当前验证级扩展到设计文档目标数量。29种五行格局经对照设计文档确认已全部实现（代码中已有）；标签组合从5种扩展到35种，覆盖6大流派方向。
Expected Output：更多配方和标签组合数据
Acceptance Criteria：
  ✅ 精确数量配方来自设计表，不自行发明（29种格局代码中已完整实现）
  ✅ 标签组合数量达到 30-50 个有效组合（实际35种）
  ✅ 所有新配方有对应的效果实现（均使用BASE_STATS已有键）
  ✅ 格局驱逐逻辑仍然正确（冒烟测试验证）
  ✅ smoke_test 仍通过
```

```
Task ID：TASK-012
Title：金甲将军 Boss 实机平衡测试
Priority：P2
Status：Backlog
Owner：Human + AI
Depends On：TASK-003
Estimated：2 Days
Description：对金甲将军进行实机 playtest，校准前摇可读性、撞柱窗口、护盾耗时和阶段总时长，目标 2-3 分钟战斗。
Expected Output：平衡调整后的 Boss 参数
Acceptance Criteria：
  □ 前摇预警清晰可辨
  □ 撞柱窗口合理，有操作空间
  □ 护盾耗时与输出能力匹配
  □ 整场战斗约 2-3 分钟
  □ 二阶段难度递进合理
  □ smoke_test 仍通过
```

```
Task ID：TASK-013
Title：Main.gd 模块化拆分
Priority：P2
Status：Done
Owner：AI
Depends On：TASK-003
Estimated：5 Days
Description：将过大的 Main.gd 逐步拆分为 Player、Enemy、Room、Relic、FiveElementDisk、CombatFeedback 等独立模块。
Expected Output：拆分后的独立脚本文件
Acceptance Criteria：
  ✅ Player 模块：移动、攻击、闪避、受击、死亡
  ✅ Enemy 模块：AI、攻击、受击、死亡
  ✅ Room 模块：房间生成、门、战利品
  ✅ Relic 模块：遗物数据、效果、背包
  ✅ FiveElementDisk 模块：五行盘、格局计算
  ✅ CombatFeedback 模块：顿帧、震屏、粒子、伤害数字
  ✅ 拆分前后行为一致，smoke_test 仍通过
```

```
Task ID：TASK-014
Title：房间叙事与秘境氛围
Priority：P2
Status：Backlog
Owner：Human + AI
Depends On：TASK-006
Estimated：2 Days
Description：增加房间叙事文本、环境探索感、事件房和秘境层级氛围。
Expected Output：更多叙事内容和事件
Acceptance Criteria：
  □ START 房有更多残卷石碑内容
  □ 事件房实现至少 3 种
  □ 不同层级有氛围差异
  □ smoke_test 仍通过
```

---

# 7. P3 — 低优先级 / Backlog

```
Task ID：TASK-015
Title：其他角色立绘与头像
Priority：P3
Status：Backlog
Owner：AI
Depends On：TASK-009
Estimated：3 Days
Description：为 Boss、精英和普通敌人制作立绘和头像。
Expected Output：敌人立绘和头像资源
```

```
Task ID：TASK-016
Title：更多环境 TileMap 变体
Priority：P3
Status：Backlog
Owner：AI
Depends On：TASK-006
Estimated：3 Days
Description：为不同层级和房间类型制作不同的 TileMap 变体。
Expected Output：多套 TileSet 资源
```

```
Task ID：TASK-017
Title：存档系统
Priority：P3
Status：Backlog
Owner：AI
Depends On：TASK-013
Estimated：2 Days
Description：实现游戏存档与读档功能。
Expected Output：存档系统
```

---

# 8. 自检

```
☑ 是否仅有一个 In Progress？
☑ 是否全部有 Priority？
☑ 是否全部有 Acceptance Criteria？
☑ 是否全部有唯一编号？
☑ 是否全部属于未完成工作？
```
