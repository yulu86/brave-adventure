# M3 · 勇士 idle + run 动画

> 阶段 B · 主角填皮 ｜ 类型：👁 新视觉 ｜ AC：—（视觉增强，无独立 AC）
> 状态：⬜ 待开发
> 上游：[技术架构 §15.2 M3](../../02_架构/01_技术架构.md)、[美术资产清单 附录 A](../../03_美术规范/01_美术资产清单.md)、[GDD §4.1](../../01_需求/01_核心玩法.md)

---

## 用户故事

**As a** 玩家，
**I want** 灰方块替换成真正的勇士精灵，静止时呼吸、移动时跑动、方向随移动翻转，
**so that** 游戏有了"主角感"，并验证 SpriteFrames + flip_h + 动画切换这条渲染链路畅通（为 M4 跳跃动画、M5 状态机内动画选择铺路）。

---

## 验收标准（AC）

| 编号 | 验收项 | Pass 判据 |
|---|---|---|
| M3-1 | 精灵替换灰方块 | 看到勇士角色（不再是青色方块），脚底与地面贴合 |
| M3-2 | idle 呼吸 | 静止时播 idle 循环动画（4 帧循环） |
| M3-3 | run 跑动 | 移动时切 run 动画（10 帧循环），停下回 idle |
| M3-4 | 方向翻转 | 向左时精灵 flip_h，向右时正向，无"倒着跑" |

---

## 技术设计要点

### 节点改造（player.tscn）

```
Player (CharacterBody2D)
- BodySprite (ColorRect) ❌ 移除
+ BodySprite (AnimatedSprite2D)  class_name 引用不变
    - SpriteFrames（新建，含 idle / run 动画）
    - offset 锚定脚底中心（Y = -sprite_height/2，避免跳位，架构 §14.2）
```

### SpriteFrames 配置（美术清单附录 A）

| 动画名 | 源纹理 | hframes | fps | loop |
|---|---|---|---|---|
| `idle` | Knight_Rank_1/idle（或对应表） | 4 | 8 | true |
| `run` | Knight_Rank_1/run | 10 | 12 | true |

> 实际源文件路径与帧数以 `docs/03_美术规范/01_美术资产清单.md` 附录 A 速查表为准（资产命名存在遗留问题，接入时核对）。

### 动画选择逻辑（仍散装在 player.gd，M5 才迁入状态机）

```gdscript
# _physics_process 末尾
var is_moving: bool = abs(velocity.x) > 1.0 and is_on_floor()
if is_moving:
    body_sprite.play("run")
else:
    body_sprite.play("idle")
if input_dir != 0.0:
    body_sprite.flip_h = input_dir < 0.0
```

### 可视化搭建协作（§12.4 强制关卡）

本里程碑涉及 `AnimatedSprite2D`（可见节点），触发 §12.4：
- **AI 先做**：用 MCP 替换节点、建空 SpriteFrames + idle/run 动画名 + 设默认 fps、指定纹理路径。
- **用户精调**：拖入实际 idle/run 帧纹理、按勇士外形精调 `offset`（脚底对齐）、确认 hframes。
- AI 输出「可视化搭建指导」+ question 暂停。

---

## 依赖

- **前置**：M1（player.gd 有 input_dir/velocity 可驱动动画选择）。
- **架构依据**：§3.5 player.tscn、§14.2 帧尺寸对齐风险。
- **被依赖**：M4（jump 动画复用同一 SpriteFrames）、M5（动画选择逻辑迁入 State）。

---

## 测试策略

- 视觉效果靠玩家手工验证（§12.5），无纯逻辑单测。
- 可补单测：`pick_animation(velocity_x, is_on_floor) -> StringName` 纯函数覆盖"移动选 run / 静止选 idle"。

---

## 验证步骤（§12.5）

1. **运行方式**：F5 启动 level.tscn。
2. **M3-1**：确认看到勇士精灵（非方块），脚底贴地。
3. **M3-2**：不动，观察 idle 呼吸循环。
4. **M3-3**：按 D 跑动观察 run 动画，松手回 idle。
5. **M3-4**：左右移动，确认朝向正确、不倒跑。

**预期**：勇士静止呼吸、移动跑动、方向翻转正确。

**异常判定**：动画不播 → SpriteFrames 是否配置帧 + `autoplay`/手动 play；跳位（精灵瞬移）→ 检查 `offset` 脚底对齐；左右都朝同一边 → `flip_h` 逻辑。
