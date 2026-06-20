# M7 · 攻击键 + AttackState

> 阶段 D · 主角战斗 ｜ 类型：🎮 新操作 ｜ AC：AC3
> 状态：⬜ 待开发
> 上游：[技术架构 §15.2 M7](../../02_架构/01_技术架构.md)、§4.3 AttackState、[GDD §4.1 攻击](../../01_需求/01_核心玩法.md)

---

## 用户故事

**As a** 玩家，
**I want** 按 J（或手柄 X 键）让勇士挥剑，挥完自动回到待机，
**so that** 具备攻击动作反馈，为 M8 命中判定铺路（本里程碑暂不产生伤害）。

---

## 验收标准（AC）

| 编号 | 验收项 | Pass 判据 |
|---|---|---|
| AC3c | 键盘攻击 | 按 J 挥剑，播 attack 动画（12 帧非循环） |
| M7-1 | 攻击冷却 | 连按 J 受 `attack_cooldown` 限制，不会帧帧挥 |
| M7-2 | 播完回 Idle | attack 动画播完自动切回 Idle |
| M7-3 | 移动中可起手 | 走/跑中按 J 可进入 Attack（Idle/Run → Attack） |
| M7-4 | 暂无命中 | 本里程碑命中框不激活，挥剑只播动画（M8 才接伤害） |

---

## 技术设计要点

### 输入与状态

- `project.godot [input]` 新增 `attack`（J 键 + 手柄 X）。
- 新增 `scripts/player/states/attack_state.gd`，player.tscn 的 StateMachine 加 AttackState 子节点。

### AttackState 关键逻辑（架构 §4.3）

```gdscript
func enter(_msg := {}) -> void:
    host.body_sprite.play("attack")
    host.body_sprite.animation_finished.connect(_on_finished)
    _cooldown_timer = host.stats.attack_cooldown
func physics_process(delta: float) -> void:
    _cooldown_timer -= delta
    # M7：命中帧激活留 M8，此处 monitoring 保持 false
func _on_finished() -> void:
    machine.transition_to("idle")   # 或根据输入回 run
func exit() -> void:
    host.body_sprite.animation_finished.disconnect(_on_finished)
```

### 状态机扩展（架构 §4.3）

- Idle/Run → Attack（按 attack 键且冷却结束）
- Attack → Idle（animation_finished）

### 数值（PlayerStats.Combat，已就绪）

- `attack_damage = 15`（M8 才用）
- `attack_cooldown = 0.45`

### 可视化搭建协作（§12.4）

涉及 AnimatedSprite2D（attack 动画配置），触发 §12.4：AI 建 attack 动画名 + 默认参数，用户拖入 Attack-01 帧纹理（hframes=12）。

---

## 依赖

- **前置**：M5（状态机框架）、M3（SpriteFrames）。
- **架构依据**：§4.3 AttackState、§6.1 PlayerStats.Combat。
- **被依赖**：M8（AttackState 命中帧激活 Hitbox）。

---

## 测试策略

### 单元测试

- AttackState enter/exit 连接/断开 animation_finished。
- 冷却判定纯函数 `can_attack(cooldown_timer) -> bool`。
- 状态切换 Idle→Attack（按 attack）、Attack→Idle（finished）。

---

## 验证步骤（§12.5）

1. **运行方式**：F5 启动 level.tscn。
2. **AC3c**：按 J，确认挥剑动画播完。
3. **M7-1**：狂按 J，确认受冷却限制（约 0.45s 一次）。
4. **M7-2**：挥完确认自动回 idle。
5. **M7-3**：跑动中按 J，确认可起手攻击。
6. **M7-4**：确认挥剑不产生任何伤害反馈（命中框未激活）。

**预期**：按 J 挥剑，有冷却，播完回 idle，暂无伤害。

**异常判定**：狂按无冷却 → 检查 `_cooldown_timer`；卡在 attack 不回 → animation_finished 是否连接。
