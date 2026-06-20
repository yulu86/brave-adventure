# M14 · TileMap 地形

> 阶段 F · 关卡 ｜ 类型：👁 新视觉 ｜ AC：—
> 状态：⬜ 待开发
> 上游：[技术架构 §15.2 M14](../../02_架构/01_技术架构.md)、§3.4 level.tscn、§3.9 碰撞层、ADR-11、[GDD §3.3 地形分层](../../01_需求/01_核心玩法.md)

---

## 用户故事

**As a** 玩家，
**I want** 关卡从一块平板地面变成有真实草地和树干的森林地形，
**so that** 视觉上进入森林场景，并确立 TileMapLayer 分层（背景/碰撞/前景）与碰撞层配置基线。

---

## 验收标准（AC）

| 编号 | 验收项 | Pass 判据 |
|---|---|---|
| M14-1 | 碰撞层中文命名 | project.godot [layer_names] 7 个 2D 物理层中文配置就绪（玩家/敌人/玩家攻击区/敌人攻击区/受击区/可碰撞地形/触发区） |
| M14-2 | 真实地形显示 | 看到 cave.tres 草地 + geometry.tres 树干瓦片（非平板） |
| M14-3 | 地形可碰撞 | 玩家/野猪踩在草地/树干上不穿落 |
| M14-4 | 分层正确 | BackgroundLayer（不碰撞）/ Ground+Geometry（碰撞）/ Foreground（前景遮挡）三层独立 |

---

## 技术设计要点

### project.godot 碰撞层命名（架构 §3.9 / ADR-11）

```ini
[layer_names]
2d_physics/layer_1="玩家"
2d_physics/layer_2="敌人"
2d_physics/layer_3="玩家攻击区"
2d_physics/layer_4="敌人攻击区"
2d_physics/layer_5="受击区"
2d_physics/layer_6="可碰撞地形"
2d_physics/layer_7="触发区"
```

> 注：M1 阶段已配置 layer_1~7 中文命名（见 project.godot），本里程碑确认并固化。

### level.tscn 地形分层（架构 §3.4 / GDD §3.3）

```
Level (Node2D, y_sort_enabled=true)
├── TileMapLayer: BackgroundLayer (background.tres, 不碰撞)
├── TileMapLayer: GeometryLayer (geometry.tres, collision_layer=可碰撞地形(32))
├── TileMapLayer: GroundLayer (cave.tres, collision_layer=可碰撞地形(32))
├── Entities (Node2D, y_sort_enabled=true)
│   └── Player / Boar / MineEntrance
└── TileMapLayer: ForegroundLayer (foreground.tres, 不碰撞, y_sort)
```

> 用现有 TileSet 资源：cave.tres（草地，命名债务保留）、geometry.tres（树干）、background.tres（树冠）、foreground.tres（树梢）。M1 的 Ground StaticBody2D 替换为 GroundLayer TileMapLayer。

### 关键决策

- **碰撞层用中文名**（ADR-11）：Inspector 勾选时一眼可读。
- **M1 平板地面替换**：StaticBody2D → TileMapLayer，保留可碰撞地形层。
- **cave.tres 命名债务保留**（架构 §14.1）：路径不改避免 UID 漂移，列为债务。

### 可视化搭建协作（§12.4 强制关卡）

TileMapLayer 瓦片绘制是典型用户精调项（§12.4），触发强制关卡：
- **AI 先做**：MCP 搭建 4 个 TileMapLayer 节点骨架 + 指定 TileSet 资源 + 配 collision_layer。
- **用户精调**：在编辑器用 TileMap 工具实际绘制草地/树干瓦片格子（AI 无法绘制瓦片）。
- AI 输出「可视化搭建指导」+ question 暂停。

---

## 依赖

- **前置**：M1（level.tscn 基础结构）、M13（实体已就绪可放地形上）。
- **架构依据**：§3.4/§3.9、ADR-11、GDD §3.3。
- **被依赖**：M15（平台高低差）、M16（坑洞）、M17（视差背景）、M22（矿洞入口放置）。

---

## 测试策略

- 视觉 + 碰撞靠玩家手工验证（§12.5）。
- 可用 MCP `godot_validate_scenes` 确认 TileSet 引用无断裂。

---

## 验证步骤（§12.5）

1. **运行方式**：F5 启动 level.tscn。
2. **M14-1**：Project Settings → Layer Names 确认 7 层中文名。
3. **M14-2**：观察草地 + 树干瓦片显示。
4. **M14-3**：玩家/野猪移动，确认踩地形不穿落。
5. **M14-4**：确认三层分层（背景在角色后、前景在前遮挡）。

**预期**：真实森林地形，分层正确，可碰撞。

**异常判定**：穿落 → TileMapLayer collision_layer 是否 32；瓦片不显示 → TileSet 引用断裂（跑 validate_scenes）。
