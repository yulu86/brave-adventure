# M8 · hitbox + 命中帧 + 静态靶

> 阶段 D · 主角战斗 ｜ 类型：⚔ 新战斗交互 ｜ AC：—（命中机制，AC7 击杀留 M13）
> 状态：⬜ 待开发
> 上游：[技术架构 §15.2 M8](../../02_架构/01_技术架构.md)、§3.7/§3.8 hitbox/hurtbox、§5.2/§5.3、ADR-3/ADR-10/ADR-13

---

## 用户故事

**As a** 玩家，
**I want** 挥剑命中时（仅挥击中段帧）对前方目标造成伤害，目标血量减少，
**so that** 攻击有真实的命中反馈，验证 hitbox→hurtbox→health 这条伤害链路打通（为 M13 击杀野猪铺路）。

---

## 验收标准（AC）

| 编号 | 验收项 | Pass 判据 |
|---|---|---|
| M8-1 | 命中帧激活 | 仅 attack 动画第 5~7 帧命中框激活（monitoring=true），其余帧关闭 |
| M8-2 | 命中扣血 | 挥剑击中静态靶，靶血量 -15 |
| M8-3 | 靶血量归零消失 | 靶血量到 0 触发 died（M8 靶可淡出/变色，不必完整死亡动画） |
| M8-4 | 无误伤 | 未在命中帧、或背对靶，不造成伤害 |

---

## 技术设计要点

### 新增组件场景（架构 §3.7/§3.8，ADR-10 场景化）

```
scenes/hitbox.tscn   class_name Hitbox (Area2D + 内置 CollisionShape2D + hitbox.gd)
scenes/hurtbox.tscn  class_name Hurtbox (Area2D + 内置 CollisionShape2D + hurtbox.gd)
scripts/components/hitbox.gd
scripts/components/hurtbox.gd
scripts/components/health.gd   class_name Health (纯逻辑 Node)
```

### 组件契约（架构 §5）

```gdscript
# health.gd
signal health_changed(new_hp: int)
signal died
@export var stats: StatsResource
var current_health: int
func take_damage(amount: int) -> void:
    if is_dead: return
    current_health = max(current_health - amount, 0)
    health_changed.emit(current_health)
    if current_health <= 0: is_dead = true; died.emit()

# hitbox.gd（攻击方）
@export var damage: int = 0
func _ready() -> void:
    area_entered.connect(_on_area_entered)
func _on_area_entered(area: Area2D) -> void:
    if area is Hurtbox:
        area.apply_damage(damage)   # 转发到对方 hurtbox → health

# hurtbox.gd（受击方）
func apply_damage(amount: int) -> void:
    health.take_damage(amount)      # @onready 引用同级 Health
```

### 命中帧激活（架构 §5.3）

```gdscript
# AttackState，监听 frame_changed
func _on_frame_changed() -> void:
    hitbox.monitoring = host.body_sprite.frame in [5, 6, 7]
```

### player.tscn 改造（架构 §3.5）

```
Player
+ Health (Node, stats=player_stats.tres)
+ Hurtbox (hurtbox.tscn 实例, layer=受击区(16), mask=—)
+ Hitbox (hitbox.tscn 实例, layer=玩家攻击区(4), mask=受击区(16), monitoring=false, damage=15)
```

> 碰撞层位掩码（项目专属经验）：玩家攻击区 layer_3 = 4，受击区 layer_5 = 16。

### 静态靶（M8 临时，M13 移除）

level.tscn 临时加一个靶节点验证伤害链：
```
Target (StaticBody2D 或 Area2D 占位)
+ Health (stats 用临时小血量)
+ Hurtbox (hurtbox.tscn 实例)
+ ColorRect（血量变化时变色反馈）
```

### 关键决策

- **击退不在组件内**（ADR-3）：take_damage 只改血量发信号；击退归 HurtState（M12 才有玩家受击，靶无需击退）。
- **Health 纯脚本，Hitbox/Hurtbox 场景化**（ADR-10/ADR-13）。
- **静态靶为临时验证物**，M13 接入真实野猪后移除。

### 可视化搭建协作（§12.4）

Hitbox/Hurtbox 的 CollisionShape2D 尺寸/偏移、layer/mask 勾选属用户精调项（按阵营/体型），触发 §12.4。

---

## 依赖

- **前置**：M7（AttackState + attack 动画）。
- **架构依据**：§3.7/§3.8/§5.1-§5.3、ADR-3/ADR-10/ADR-13。
- **被依赖**：M12（玩家受击复用 Hurtbox/Health）、M13（击杀野猪复用整条伤害链）。

---

## 测试策略

### 单元测试（架构 §11 重点）

- `test_health.gd`：take_damage 正常扣血、0 血边界、died 信号触发、is_dead 后不再扣。
- hitbox→hurtbox 转发：mock area_entered 验证 damage 传递。

### 集成测试（`test/integration/player/`）

- AttackState 命中帧激活：frame_changed 时 monitoring 在 [5,7] 为 true、其余 false。
- Attack 命中靶 → 靶 Health 扣血 → 血量归零 died。

---

## 验证步骤（§12.5）

1. **运行方式**：F5 启动 level.tscn（含临时靶）。
2. **M8-1**：（可开 collision shape debug）确认命中框仅 5~7 帧显示。
3. **M8-2**：站靶前挥剑，观察靶血量减少（变色/数值）。
4. **M8-3**：多挥几次至血量归零，靶消失/淡出。
5. **M8-4**：背对靶、或在非命中帧挥，确认不扣血。

**预期**：挥剑命中段帧扣血，靶归零消失，无误伤。

**异常判定**：始终扣血 → 命中帧 monitoring 未正确关闭；不扣血 → 检查 layer/mask（玩家攻击区 4 / 受击区 16）、hitbox.damage 是否设值。
