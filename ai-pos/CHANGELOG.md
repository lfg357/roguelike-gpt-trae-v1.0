# CHANGELOG.md — 变更历史

---

# 1. 文档职责

CHANGELOG.md 记录已完成的变更。所有内容必须已经发生，不得记录未来计划。

---

# 2. 记录时机

任务完成、模块完成、版本发布、重要 Bug 修复、重大设计实施。普通讨论无需记录。

---

# 3. 变更记录

```
Date：2026-07-14
Type：Fix/Refactor
Module：战斗/视觉/文档
Related Task：实机视觉验收（TASK-003）
Summary：修复三个实机验收问题

Details：
1. 修复清空房间时特效残留问题：
   - 在 _clear_room() 末尾添加 combat_feedback_module.clear_all() 和 slash = {}
   - 确保房间清空时立即清除所有特效（刀光、粒子、弹幕等）
   - 不再需要等到进入下一个房间才清除

2. 补全设计规格.md中35种标签组合的详细效果：
   - 每个组合新增效果属性、数值、详细描述、视觉表现四个字段
   - 完整记录每种组合的具体效果，便于开发和测试参考
   - 所有数据与代码实际实现保持一致

3. 修复单字标签显示激活状态问题：
   - 移除 _active_disk_tags() 的效果按钮显示
   - 单字标签不再单独展示，只有完整组合才显示激活状态
   - 符合设计文档要求：未激活的组合不必特殊展示

Impact：
- 房间清空时弹幕/特效立即消失，不再残留
- 设计规格文档完整记录所有标签组合数据
- UI界面不再显示未激活的单字标签
Operator：AI
```

```
Date：2026-07-14
Type：Fix
Module：战斗系统/UI/特效
Related Task：实机测试修复
Summary：修复4项实机测试发现的问题

Details：
1. 攻击命中后画面卡死修复：
   - 原因：_process 中 hit_stop 期间提前 return，导致 player_module.update_timers() 不执行，attack_cd 不递减
   - 玩家在冻结期间持续按攻击键，每次命中调用 _hit_stop 重置时间，造成永久冻结
   - 修复：将 player_module.update_timers(delta) 移到 hit_stop 检查之前执行

2. 五行盘拖拽松手自动放置修复：
   - 原因：_unhandled_input 中的鼠标松开事件可能被 GUI 控件优先捕获（如效果按钮、标签等）
   - 修复：在 _process 中添加拖拽状态检查，通过 Input.is_mouse_button_pressed() 检测左键是否松开

3. 特效描述信息完善：
   - VFX_DESCRIPTIONS 中每个特效的描述从简短说明扩展为详细表现描述
   - 补充特效视觉细节、持续时间、颜色、触发条件等信息

4. F8键退出游戏修复：
   - 原因：_debug_animation_review() 中 await process_frame，但 process_frame 信号未定义和发射
   - 协程永远挂起导致游戏崩溃退出
   - 修复：新增 signal process_frame()，并在 _process 末尾 emit_signal("process_frame")

Impact：修复实机测试中发现的关键问题，提升游戏稳定性和交互体验
Operator：AI
```

```
Date：2026-07-14
Type：Fix
Module：语法/构建
Related Task：编译错误修复
Summary：修复类型推断导致的编译错误

Details：
- 错误：Cannot infer the type of "in_hit_stop" variable because the value doesn't have a set type.
- 位置：scripts/Main.gd 第848行
- 原因：使用 := 声明比较表达式结果的变量，GDScript 无法推断类型
- 修复：将 var in_hit_stop := ... 改为 var in_hit_stop: bool = ...
- 教训：所有变量必须显式声明类型，禁止依赖类型推断

Impact：修复工程无法打开的严重问题
Operator：AI
```

```
Date：2026-07-14
Type：Fix
Module：视觉/动画/五行系统
Related Task：实机视觉验收（TASK-003）
Summary：修复4项实机视觉验收发现的问题

Details：
1. 怪物锚点错位修复：
   - 原因：BASE_ANCHORS 和 ANCHOR_TRACKS 中的锚点 y 值偏低（0.77-0.86），导致怪物脚部悬空
   - 修复：将所有怪物锚点 y 值调整到 0.92-0.94，使怪物脚部精确对齐逻辑位置
   - 文件：scripts/art/CharacterSequences.gd 第43-65行

2. 角色受击后上半身展示修复：
   - 原因：anchor() 返回相对于区域尺寸的坐标，但绘制时使用固定 draw_size，导致锚点偏移
   - 修复：anchor() 末尾添加尺寸比例转换，使锚点适配固定 draw_size
   - 文件：scripts/art/CharacterSequences.gd 第127-144行

3. 五行圆满特效错误触发修复：
   - 原因：_trigger_yuan_pulse() 未检查玩家是否激活了"五行圆满"格局，只要 stats["yuan_pulse"] > 0 就触发
   - 修复：在 _trigger_yuan_pulse() 开头添加格局检查，必须包含"五行圆满"才执行
   - 文件：scripts/Main.gd 第1525-1527行

4. 玩家受击动画锚点调整：
   - 原因：玩家受击动画锚点 y 值偏低，导致受击时角色位置偏移
   - 修复：玩家 hurt 动作锚点从 Vector2(0.45, 0.74) 调整为 Vector2(0.50, 0.88)
   - 文件：scripts/art/CharacterSequences.gd 第44行

Impact：修复实机视觉验收中发现的关键问题，提升角色展示准确性和五行系统平衡性
Operator：AI
```

```
Date：2026-07-14
Type：Revert
Module：视觉/锚点
Related Task：实机视觉验收（TASK-003）
Summary：回退所有锚点相关改动，恢复原始状态

Details：
- 回退 BASE_ANCHORS 中所有锚点坐标到原始值
- 回退 ANCHOR_TRACKS 中所有锚点轨迹到原始值
- 回退 anchor() 函数中添加的尺寸比例转换逻辑
- frame_draw_size() 保持使用固定 draw_size（原始行为）

Reason：锚点改动导致所有角色形象飞起来，位置严重偏移，影响游戏正常运行

Impact：角色位置恢复到原始状态，形象不再漂浮；其他修复（五行圆满、攻击卡死、拖拽、F8）保持有效
Operator：AI
```

```
Date：2026-07-14
Type：Docs
Module：质量保障
Related Task：代码审查制度建立
Summary：建立代码审查制度与显式类型声明规则

Details：
- 创建 docs/CODE_REVIEW.md：完整代码审查规范文档
  - 审查流程：自检 → 语法检查 → 冒烟测试 → 提交
  - 检查清单：GDScript语法规范、架构规范、功能完整性、性能稳定性、配置资源
  - 常见陷阱：类型推断、字典访问、信号连接、节点生命周期
  - 修改分级与测试要求：轻微/一般/重要/重大四级
  - 文档同步要求
- MEMORY.md 新增 Rule-014（代码审查原则）和 Rule-015（显式类型声明原则）

Impact：建立代码质量保障机制，防止编译错误和隐性bug进入代码库
Operator：AI
```

```
Date：2026-07-14
Type：Test
Module：测试执行
Related Task：核心功能测试 + 回归测试
Summary：执行核心功能测试与回归测试，全部通过
Details：
- 编写 tests/core_function_test.gd：15项核心功能自动化测试用例
- 编写 tests/regression_test.gd：31项回归测试用例
- 执行核心功能测试：15/15 PASS
- 执行回归测试：31/31 PASS
- 执行冒烟测试：PASS（state=dead floor=2 rooms=30）
- 执行动画深度测试：PASS（vfx=34 character_states=29）
- 测试覆盖：五行系统、层间切换、遗物系统、战斗系统、动画VFX、输入UI
Impact：验证当前代码库稳定性，建立测试基线，为后续开发提供回归保障
Operator：AI
```

```
Date：2026-07-14
Type：Docs
Module：测试体系
Related Task：QA测试体系建立
Summary：建立完备测试体系文档与缺陷跟踪流程
Details：
- 编写 docs/TEST_PLAN.md：测试策略、范围、4阶段流程、准入准出标准、S/A/B/C/D缺陷分级
- 编写 docs/TEST_CASES.md：核心功能40项用例（五行10 + 层间切换10 + 遗物10 + 战斗10）
- 编写 docs/REGRESSION_SCOPE.md：50项回归测试清单 + 精简回归策略
- 编写 docs/BUG_TRACKING.md：缺陷生命周期、提单/修复模板、统计指标
- 编写 docs/ACCEPTANCE_CHECKLIST.md：F6-F11实机视觉验收 + P0闸口评分
- 创建 tests/bugs/ACTIVE/、tests/bugs/CLOSED/、tests/bugs/BUG_STATISTICS.md
- 同步更新 HANDOFF.md §14 记录测试体系建立
Impact：测试体系从"有脚本无文档"升级为完备文档体系，支持冒烟/功能/回归/验收四阶段测试
Operator：AI
```

```
Date：2026-07-14
Type：Docs
Module：设计规格
Related Task：设计规格汇总
Summary：建立设计规格汇总文档
Details：
- 编写 设计规格.md（项目根目录），汇总设计文档 v4.0 与代码实际实现数据
- 遗物规格：42件完整清单（P0通用14 + P1通用18 + 燕无归专属4 + 配方10）
- 敌人规格：25种敌人规格卡 + 6种AI + 数值递进系数 + 元素克制
- 武器规格：20把角色专属武器 + 5种兵器类型 + 获取规则
- 标签组合：35种组合 + 20个标签体系
- 五行格局：29种完整配方（单元素5 + 相生双元5 + 相克双元5 + 三元相生链5 + 混合三元5 + 四元3 + 圆满1）
- 验收标准：P0/P1/P2三层闸口
Impact：建立项目唯一数据基准文档，供开发/测试/平衡调参参考
Operator：AI
```

```
Date：2026-07-14
Type：Refactor
Module：架构
Related Task：TASK-013
Summary：Main.gd 模块化拆分完成
Details：将过大的 Main.gd 拆分为 6 个独立模块：
- Player.gd：玩家移动、攻击、闪避、受击、死亡逻辑，计时器更新
- Enemy.gd：敌人 AI、攻击、受击、死亡逻辑
- Room.gd：房间生成、门连接、进入房间、下一层逻辑
- Relic.gd：遗物数据、背包管理、随机遗物、买卖价格
- FiveElementDisk.gd：五行盘操作、格局计算、预览评估
- CombatFeedback.gd：顿帧、震屏、粒子、伤害数字、死亡演员

采用"工具类模式"：模块通过引用 Main 节点操作共享数据，避免数据复制和同步问题。Main.gd 保留核心私有方法（_attack、_dodge、_evaluate_build 等）供模块调用。

修复所有语法错误和缺失字段问题：
- 添加缺失的 player 字段（invuln、hurt、haste、guard、rage、radius、facing、base_speed、combo_expire）
- 添加缺失的 Main 变量（screen_shake）
- 使用 get() 安全访问可能不存在的字段

冒烟测试和动画深度测试均通过，拆分前后行为一致。
Impact：代码组织更清晰，各模块职责明确，提升可维护性和可测试性
Operator：AI
```

```
Date：2026-07-14
Type：Feature
Module：五行系统
Related Task：TASK-010（部分）
Summary：五行盘拖拽交互完善（完整拖拽 + 实时预览）

Details：实现完整的五行盘拖拽交互系统，包括：
- 拖入：从背包拖拽遗物到五行盘空槽位或替换已有遗物
- 拖出：从五行盘拖拽遗物回背包或取消拖拽放回原位
- 盘内互换：直接拖动盘内遗物到其他槽位交换位置
- 实时预览：拖动过程中实时计算放入目标槽位后的格局和标签组合，显示在 build_label 中
- 目标高亮：拖到槽位上方时显示绿色高亮边框提示
- 跟随精灵：拖动时显示半透明精灵跟随鼠标

Impact：五行盘交互体验大幅提升，玩家可直观预览构筑变化，操作流畅度显著改善
Operator：AI
```

```
Date：2026-07-14
Type：Feature
Module：五行系统
Related Task：TASK-011（部分）
Summary：扩展标签组合从 5 种到 35 种
Details：对照设计文档 v4.0 附录 D 确认 29 种五行格局已全部实现。将 TAG_COMBOS 从 5 种扩展到 35 种，覆盖暴击/攻击流 6 种、灼烧/持续伤流 5 种、防御/生存流 6 种、控制/限制流 5 种、机动/闪避流 4 种、召唤/特殊流 4 种。所有效果均使用 BASE_STATS 已有键，无需新增机制代码。冒烟测试新增标签组合验证断言（破甲墨锋、焰刃、多组合并存），全部通过。
Impact：五行构筑多样性显著提升，从验证级达到设计文档目标数量级
Operator：AI
```

```
Date：2026-07-14
Type：Verify
Module：测试
Related Task：TASK-002
Summary：状态验证全部通过
Details：运行三项验证：Godot headless 解析（exit_code 0，无错误）、smoke_test.gd（SMOKE_OK state=dead floor=2 rooms=30）、animation_deep_test.gd（ANIMATION_DEEP_OK vfx=34 character_states=29）。所有测试 exit_code 0，无断言失败。
Impact：确认项目当前可稳定运行，角色动画 29 个状态、VFX 34 条序列全部通过深度审计
Operator：AI
```

```
Date：2026-07-14
Type：Docs
Module：ai-pos
Related Task：TASK-001
Summary：补齐 ai-pos 文档体系所有占位内容
Details：将 ai-pos/ 目录下 6 个文档（PROJECT、MEMORY、CURRENT、DECISIONS、TODO、CHANGELOG）中的占位符全部替换为项目实际内容。基于 HANDOFF.md 和项目代码提取项目定义、长期规则、当前状态、设计决策、任务队列和变更历史。
Impact：ai-pos 文档体系完整可用，新 Agent 可通过文档快速恢复项目状态
Operator：AI
```

```
Date：2026-07-14
Type：Feature
Module：动画/VFX 系统
Related Task：HANDOFF §12、§13
Summary：特效定位修复与动画深度验证
Details：
- 修复元素/成长/精英图集非等宽排布导致的偏移问题，改用逐行真实帧边界
- 新增 VFX 逐帧语义锚点，当前帧和下一帧分别按自己的锚点构造绘制矩形
- 人物不再在切换贴图前插值锚点，避免"旧帧先滑向下一帧脚点"
- 拾取特效绑定交互完成时的玩家位置，鼠标方向改用 get_global_mouse_position()
- 项目拉伸模式改为 keep，1280x720 设计坐标等比缩放留边
- 玩家和敌人 idle/run 都有独立循环时钟，动作状态切换从第 0 帧开始
- 新增 tests/animation_deep_test.gd 深度测试
- 新增 tools/validate_animation_sequences.py 离线资源审计工具
Impact：角色和特效定位精度大幅提升，动画系统更健壮，测试覆盖更完整
Operator：Human + AI
```

```
Date：2026-07-14
Type：Fix
Module：VFX 生命周期
Related Task：HANDOFF §12
Summary：修复成长类 VFX 连续触发残留问题
Details：
- 拾取、武器获得、格局激活、五行圆满等成长类 VFX 共用 progression 重启槽位
- 新效果触发时先移除同槽位旧实例，再从第 0 帧重新播放
- 命中、暴击、破盾、死亡等战斗反馈仍允许多实例并存
- VFXSequences 增加 frame_count(kind)，对空尾帧序列只播放有效帧
Impact：成长类特效不再多层残留，战斗反馈与成长反馈的生命周期策略分离
Operator：Human + AI
```

```
Date：2026-07-13
Type：Refactor
Module：动画渲染系统
Related Task：HANDOFF §5
Summary：动画渲染重构——从静态图集到逐帧动作序列
Details：
- 角色美术从静态 atlas 改为逐动作独立时间序列
- VFX 从多层静态贴图叠加改为独立时间序列，每条序列对应一个语义事件
- 人物采用"单帧占优"策略，任何时刻只绘制一张完整人物贴图
- 能量特效只在帧尾 26% 做极短融合，两帧 alpha 之和恒为 1
- 脚点锚点以源帧归一化坐标记录，燕无归和精英使用逐帧锚点轨道
- 战斗区由 758x482 扩为 848x548，角色绘制尺寸同步缩小
- 右侧栏压缩到 266px，地图单元调为 32px
- 资源目录重组：source/ 放绿幕源文件（.gdignore），animated/ 和 sequences/ 放运行时透明 PNG
- 旧 atlases 仅保留为概念参考，Main.gd 不再预加载
- 新增 docs/ANIMATION_RENDERING.md 动画渲染规范
Impact：美术表现从静态叠加升级为真正的逐帧动画，动作语义清晰，符合附录 G 要求
Operator：Human + AI
```

```
Date：2026-07-12
Type：Feature
Module：五行系统
Related Task：HANDOFF §4.3
Summary：五行格局驱逐机制与圆满均衡化
Details：
- 实现五行高级格局驱逐低级格局：同一批元素只触发一个主导格局
- 格局层内部按"精确签名 > 等阶 > 元素覆盖 > 优先级"排序选择
- 五行圆满从全属性尖峰调整为均衡小幅提升
- 支持精确数量签名（exact_counts / exact_total）能力接口
- 相克双元接入双刃剑方向（破甲/击杀收益/泥沼/蒸汽/暴击灼烧及对应惩罚）
- 三元/四元格局接入 P0 轻量版，用于验证高级驱逐低级
Impact：五行构筑更有深度，高阶格局有价值，五行圆满定位回归均衡
Operator：Human + AI
```

```
Date：2026-07-11
Type：Feature
Module：核心玩法
Related Task：HANDOFF §4
Summary：P0 核心玩法闭环完成
Details：
- 完成主菜单、准备房、战斗房、精英房、商店、Boss、奖励、层间结算、死亡/胜利结果页全流程
- 实现 5x6 后台迷宫拓扑，含 START/MONSTER/ELITE/SHOP/BOSS 节点
- 房间出口根据地图连接计算，支持 8 方向连接，商店和已清房间保留返回出口
- START 房加入残卷石碑交互和叙事提示
- 实现 WASD 移动、鼠标攻击、闪避、副技能、三段连击、顿帧、震屏、击退、伤害飘字
- 接入燕无归 5 把正式武器 + 15 个副技能变体
- 实现 P0 敌人：刀灵、铜甲、镖手、金甲精英、金甲将军 Boss
- Boss 两阶段、金盾、火破金盾加倍、劈砍/环扫/冲刺、石柱阻挡、撞柱眩晕、半血转木阶段
- 实现 14 件 P0 通用遗物和标签组合验证
- 实现五行盘、商店购买/刷新/出售、武器抉择、Boss 战利品 + 漩涡门 + 延迟结算
- 统一水墨 UI 主题，1280x720 布局
- 埋点骨架：run_start、room_enter、room_clear、relic_get、weapon_get、pattern_activated、death、run_end、lore_read
Impact：P0 核心玩法闭环完整可玩，冒烟测试通过
Operator：Human + AI
```

```
Date：2026-06
Type：Feature
Module：项目初始化
Related Task：-
Summary：项目初始化与早期原型
Details：
- 创建 Godot 4.7 项目，设置 1280x720 视口
- 建立基础项目目录结构
- 接入早期静态角色图集和 VFX 图集（概念参考）
- 实现基础移动和攻击原型
Impact：项目骨架建立，可运行基础原型
Operator：Human + AI
```

---

# 4. 组织方式

时间倒序，最新在前。

---

# 5. 版本发布

（暂无正式版本发布）

---

# 6. 自检

```
☑ 已完成？
☑ 可验证？
☑ 包含日期？
☑ 包含类型？
☑ 包含模块？
☑ 包含影响范围？
```
