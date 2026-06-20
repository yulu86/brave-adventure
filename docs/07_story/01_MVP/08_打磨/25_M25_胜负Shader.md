# M25 · 胜负 Shader

> 阶段 H · 打磨 ｜ 类型：✨ 新特效 ｜ AC：—（视觉增强，AC10/AC11 的特效部分）
> 状态：⬜ 待开发
> 上游：[技术架构 §15.2 M25](../../02_架构/01_技术架构.md)、§9 Shader、ADR-7、[GDD §9](../../01_需求/01_核心玩法.md)

---

## 用户故事

**As a** 玩家，
**I want** 胜利画面有金色光波 + 泛光，死亡画面有碎裂 + 灰度效果，
**so that** 胜负时刻有强烈的视觉冲击与情感反馈，提升打磨质感。

---

## 验收标准（AC）

| 编号 | 验收项 | Pass 判据 |
|---|---|---|
| M25-1 | 胜利金色光波 | win_screen 显示金色光波从中心扩散 |
| M25-2 | 胜利泛光 | 画面亮部泛光提亮 |
| M25-3 | 死亡碎裂 | death_screen 画面碎裂成块扩散 |
| M25-4 | 死亡灰度 | 画面灰度化、向暗压缩 |
| M25-5 | 无渲染报错 | shader 编译无错，画面无黑屏/穿帮 |

---

## 技术设计要点

### Shader 资产（架构 §9.3 / GDD §9.3，从零手写）

```
assets/shaders/win_glow.gdshader       (canvas_item)
assets/shaders/death_shatter.gdshader  (canvas_item)
assets/shaders/noise.tres              (NoiseTexture2D, FastNoiseLite)
```

### 胜利 win_glow.gdshader（架构 §9.1）

| 效果 | 实现 |
|---|---|
| 泛光 | 提取亮部 → 高斯模糊 → 叠加 |
| 金色光波 | TIME 驱动、屏幕中心圆心扩张圆环，金色 modulate |

uniform：`TIME`（内置）、`wave_intensity`、`bloom_threshold`。

### 死亡 death_shatter.gdshader（架构 §9.2）

| 效果 | 实现 |
|---|---|
| 碎裂 | noise.tres 驱动 UV 偏移，画面撕裂成块扩散 |
| 灰度 | RGB 转 luma，向暗压缩 |

uniform：`crack_intensity`(0→1)、`shake_amount`。

### 接入方式（ADR-7：全屏 ColorRect，非后处理抓帧）

```
win_screen.tscn:
+ ShaderLayer (CanvasLayer layer=50)
    └── GlowRect (ColorRect, 全屏, material=ShaderMaterial[win_glow])

death_screen.tscn:
+ ShaderLayer (CanvasLayer layer=50)
    └── ShatterRect (ColorRect, 全屏, material=ShaderMaterial[death_shatter])
```

> M22/M23 已建 win_screen/death_screen 骨架（GlowRect/ShatterRect 留空），M25 接入实际 shader。

### 触发时序（GDD §9）

- 胜利：进 win_screen 后 _ready 触发 shader（TIME 从 0 扩散 2s）+ UI 淡入。
- 死亡：death_screen 触发碎裂（crack_intensity 0→1）+ 灰度。

### 关键决策

- **全屏 ColorRect 而非后处理抓帧**（ADR-7）：避免 BackBufferCopy 复杂度，shader 作用于遮罩层。
- **Shader 可手写**（宪法 §12.1 例外）：非场景文件，但接入后须编辑器预览 + 玩家试玩验证（§12.5）。
- **noise.tres 复用 Godot 内置 FastNoiseLite**（GDD §9.3）。

### 可视化搭建协作（§12.4）

Shader 参数（wave_intensity / bloom_threshold / crack_intensity / shake_amount）属精调项，需编辑器预览 + 试玩调参。

---

## 依赖

- **前置**：M22（win_screen 骨架）、M23（death_screen 骨架）。
- **架构依据**：§9、ADR-7、GDD §9。
- **被依赖**：M26（胜负画面视觉验收）。

---

## 测试策略

- shader 视觉效果靠编辑器预览 + 玩家手工试玩（§12.5），无纯逻辑单测。
- 可用 `godot_lint_shader` 检查编译错误（G02 衍生）。

---

## 验证步骤（§12.5）

1. **运行方式**：F5 进关卡，分别触发胜利（走到终点）和死亡（送死）。
2. **M25-1/2**：胜利画面观察金色光波扩散 + 泛光提亮。
3. **M25-3/4**：死亡画面观察碎裂扩散 + 灰度。
4. **M25-5**：确认无黑屏/编译报错/穿帮。

**预期**：胜利金色光波+泛光，死亡碎裂+灰度，无报错。

**异常判定**：黑屏 → shader 编译错（检查 uniform/语法）；无效果 → ShaderMaterial 未赋给 ColorRect；效果过强/弱 → 调 uniform 参数。
