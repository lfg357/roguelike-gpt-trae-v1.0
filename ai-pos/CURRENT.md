# CURRENT.md — 项目运行状态

---

# 1. 当前状态

## 项目状态

```
Developing
```

可选值：Planning / Designing / Developing / Testing / Reviewing / Deploying / Maintaining / Completed / Archived

## 当前阶段

```
P0 可玩骨架与附录 G 美术基础落地 — 测试基线建立完成
```

## 当前模块

```
测试体系建立 + 实机视觉验收准备
```

## 负责人

```
用户 + AI
```

---

# 2. 当前任务

| 字段 | 内容 |
|------|------|
| TASK-ID | TEST-001 |
| 标题 | 测试体系建立与执行 |
| 目标 | 建立完备的测试体系文档和自动化测试脚本，执行核心功能测试和回归测试，验证代码库稳定性 |
| 状态 | Completed |
| 开始时间 | 2026-07-14 |

同一时间仅允许一个 Current Task。

---

# 3. 当前目标

完成实机视觉验收（阶段 A），确认角色动作、VFX 特效、UI 布局在 1280x720 下无问题，为后续美术资源制作和接入奠定基础。

---

# 4. 当前输入 / 输出 / 风险

| 输入 | 输出 | 风险 |
|------|------|------|
| 测试脚本执行结果 | 测试报告 + 测试基线 | 测试覆盖不全导致遗漏问题 |
| F6-F11 Debug 入口 | 视觉验收检查清单 | 视觉验收主观性较强 |
| 设计文档 v4.0 | 美术资源制作计划 | 美术资源与代码整合困难 |
| HANDOFF.md | 项目状态更新 | 文档更新不及时 |

---

# 5. 阻塞项

```
None
```

---

# 6. 下一步

进入实机视觉验收阶段（TASK-003）：使用 F6-F11 Debug 入口进行实机视觉检查，确认角色动作、VFX 特效、UI 布局在 1280x720 下无问题。验收通过后推进附录 G 的 P0 缺口：水墨粒子批次（TASK-004）、顿帧叠加层与伤害数字（TASK-005）、TileMap 与秘境门视觉（TASK-006）。

---

# 7. 恢复快照（Recovery Snapshot）

新 Agent 接管时只需阅读本节（≤300 字）：

```
Project：仙途·墨渊（修仙俯视角 Roguelike）
Phase：P0 可玩骨架与附录 G 美术基础落地 — 测试基线建立完成
Module：测试体系
Task：TEST-001 - 测试体系建立与执行
Progress：冒烟测试+动画深度测试+核心功能测试(15/15)+回归测试(31/31)全部通过，已建立测试基线
Owner：用户 + AI
Blocking：None
Next：实机视觉验收（TASK-003）→ 水墨粒子（TASK-004）→ 顿帧叠加层（TASK-005）→ TileMap（TASK-006）
Last Updated：2026-07-14
```

---

# 8. 会话记忆（Session Notes / L1.5）

跨对话轮次但不永久存储的临时信息。上下文压缩前写入，任务完成后清理。

## 项目快速参考

- **引擎**：Godot 4.7 stable
- **主场景**：`scenes/Main.tscn`
- **主逻辑**：`scripts/Main.gd`
- **设计文档**：`《仙途·墨渊》设计文档 v4.0.md`
- **冒烟测试**：`tests/smoke_test.gd`
- **动画深度测试**：`tests/animation_deep_test.gd`
- **最新测试结果**：
  - Godot headless 解析：✅ 通过（exit_code 0，无错误）
  - 冒烟测试：✅ 通过 `SMOKE_OK state=dead floor=2 rooms=30`
  - 动画深度测试：✅ 通过 `ANIMATION_DEEP_OK vfx=34 character_states=29`
  - 核心功能测试：✅ 通过 15/15
  - 回归测试：✅ 通过 31/31
- **测试脚本**：
  - `tests/core_function_test.gd`：15项核心功能自动化测试
  - `tests/regression_test.gd`：31项回归测试
- **Godot 路径**：`C:\Users\AdminLFG\AppData\Local\Programs\Godot\Godot_v4.7-stable_win64_console.exe`

## 关键 Debug 入口

- F6/6：锚点审阅场（青色目标十字）
- F7/7：成长 VFX 生命周期检查
- F8/8：角色单帧交接、刀光和能量融合
- F9：角色美术展示场
- F10：直达 Boss 房
- F11：强制 Boss 二阶段

## 最近一轮完成的工作（2026-07-14）

1. 补齐 ai-pos 文档体系（PROJECT/MEMORY/CURRENT/DECISIONS/TODO/CHANGELOG）
2. 状态验证：Godot headless 解析通过 + 冒烟测试通过 + 动画深度测试通过
3. 扩展五行格局：确认 29 种格局已全部实现（单元素 5 + 相生双元 5 + 相克双元 5 + 三元相生链 5 + 混合三元 5 + 四元 3 + 五行圆满 1）
4. 扩展标签组合：从 5 种扩展到 35 种（暴击/攻击 6 种 + 灼烧/持续伤 5 种 + 防御/生存 6 种 + 控制/限制 5 种 + 机动/闪避 4 种 + 召唤/特殊 4 种）
5. 五行盘拖拽交互完善：完整拖拽 + 实时预览格局变化
   - 拖入：从背包拖入空槽位或替换已有遗物
   - 拖出：从五行盘拖回背包或取消拖拽放回原位
   - 盘内互换：直接拖动盘内遗物到其他槽位交换
   - 实时预览：拖动时实时计算并显示放入后的格局和标签组合
   - 目标高亮：拖到槽位上方时绿色高亮提示
6. 更新冒烟测试：新增标签组合验证（破甲墨锋、焰刃、多组合并存）
7. 修复成长类 VFX 连续触发残留：共用 progression 重启槽位
8. VFX 序列支持有效帧数与资源格数分离（部分序列只播前 7 帧）
9. 敌人新增独立 loop_clock
10. 新增 validate_animation_sequences.py 离线审计工具
11. 修复元素/成长/精英图集非等宽排布导致的偏移问题
12. 新增 animation_deep_test.gd 深度测试
13. 拾取特效绑定交互完成时玩家位置
14. 鼠标方向改用 get_global_mouse_position()
15. 项目拉伸模式改为 keep

## 已知剩余风险

- 燕无归、铜甲、Boss 部分源帧仍触碰等宽动作行边界（运行时裁剪可处理）
- 金甲精英披挂/刀身贴边与质心跳变（建议后续重制动作表）
- animation_deep_test.gd 上次因进程启动失败未完整复跑，需优先验证
