# M11 · ChaseState + 追击

> 阶段 E · 野猪 AI ｜ 类型：🤖 新敌人行为 ｜ AC：AC6
> 状态：⬜ 待开发
> 上游：[技术架构 §15.2 M11](../../02_架构/01_技术架构.md)、§4.4、§5.4 侦测、ADR-4、[GDD §5.1/§5.4](../../01_需求/01_核心玩法.md)

---

## 用户故事

**As a** 玩家，
**I want** 靠近野猪时它发现我并冲过来追，跑远了它放弃回巡逻，
**so that** 野猪具备威胁性的 AI（巡逻↔追击状态切换），验证 DetectArea 侦测 + Boar 对 Player 解耦设计。

---

## 验收标准（AC）

| 编号 | 验收项 | Pass 判据 |
|---|---|---|
| AC6a | 进入侦测即追击 | 玩家进入 DetectArea（≤detect_range），野猪切 Chase 朝玩家冲 |
| M11-1 | 追击速度 | 追击速度 = `chase_speed`（120），快于巡逻 |
| M11-2 | 脱战回巡逻 | 玩家脱离 lose_range 超过 lose_time（2s），野猪回 Patrol |
| M11-3 | run 动画 | 追击时播 run 动画 |
| M11-4 | 追玩家位置 | 朝玩家 global_position.x 方向移动（不 import Player 类） |

---

## 技术设计要点

### 新增节点与状态（架构 §3.6 / §4.4）

```
Boar
+ DetectArea (Area2D, layer=触发区(64), mask=玩家(1))
│   └── DetectShape (CollisionShape2D, CircleShape2D r=detect_range)
StateMachine
+ ChaseState
```

> 碰撞层位掩码：触发区 layer_7 = 64，玩家 layer_1 = 1。

### ChaseState 逻辑（架构 §4.4 + ADR-4 解耦）

```gdscript
func enter(_msg := {}) -> void:
    host.body_sprite.play("run")
    host.hitbox.monitoring = true   # 追击时激活伤害区（接触玩家扣血，伤害结算留 M12）
func physics_process(delta: float) -> void:
    var target: Node2D = host.detected_target   # DetectArea.body_entered 时存入
    if is_instance_valid(target):
        host.facing_dir = sign(target.global_position.x - host.global_position.x)
        host.velocity.x = host.facing_dir * host.stats.chase_speed
    host.move_and_slide()
    # 脱战计时
    _lose_timer += delta
    if not host.is_target_in_range(host.stats.lose_range) and _lose_timer > host.stats.lose_time:
        machine.transition_to("patrol")
```

### DetectArea 侦测（架构 §5.4）

```gdscript
# boar.gd
func _on_detect_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):   # 或物理层判定，不 import Player
        detected_target = body
        state_machine.transition_to("chase")
```

### 状态切换（架构 §4.4）

- Patrol → Chase：DetectArea.body_entered（玩家进入）
- Chase → Patrol：脱离 lose_range 超 lose_time

### 数值（BoarStats）

- `chase_speed = 120`、`detect_range = 120`、`lose_range = 240`、`lose_time = 2.0`

### 可视化搭建协作（§12.4）

DetectArea 的 CircleShape2D 半径、Hitbox 尺寸/偏移属用户精调项，触发 §12.4。

---

## 依赖

- **前置**：M9/M10（boar.tscn + Patrol + 填皮）。
- **架构依据**：§3.6/§4.4/§5.4、ADR-4、§6.1。
- **被依赖**：M12（玩家受击，Chase 时 Hitbox 接触玩家）、M13（击杀）。

---

## 测试策略

### 集成测试（`test/integration/enemy/`）

- DetectArea body_entered 触发 Chase（用 mock body 进 group "player"）。
- 脱战 lose_time 回 Patrol。
- Chase 朝 mock target 位置移动（不 import Player）。

---

## 验证步骤（§12.5）

1. **运行方式**：F5 启动 level.tscn（玩家 + 野猪）。
2. **AC6a**：靠近野猪（进入侦测圆），确认它转向冲过来。
3. **M11-1/3**：观察追击速度更快、播 run。
4. **M11-2**：跑远（超出 lose_range）并等待 2s+，确认野猪放弃回巡逻。
5. **M11-4**：左右横跳，确认野猪跟随玩家位置。

**预期**：靠近被追、跑远被放弃，追击播 run 速度更快。

**异常判定**：不追 → DetectArea layer/mask（触发区 64 / 玩家 1）、玩家是否在 group；永不脱战 → lose_range/lose_time 计时。
