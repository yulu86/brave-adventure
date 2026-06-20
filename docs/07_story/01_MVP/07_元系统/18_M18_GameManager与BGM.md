# M18 · GameManager + BGM

> 阶段 G · 元系统 ｜ 类型：🎵 新音频/全局服务 ｜ AC：AC14
> 状态：⬜ 待开发
> 上游：[技术架构 §15.2 M18](../../02_架构/01_技术架构.md)、§3.1 game_manager.tscn、§8 GameManager、ADR-5、[GDD §8.2/§8.6](../../01_需求/01_核心玩法.md)

---

## 用户故事

**As a** 玩家，
**I want** 进入关卡就听到森林 BGM 循环播放，
**so that** 有沉浸式听觉体验，并确立 GameManager（Autoload）作为跨场景全局服务（BGM/HUD/暂停）的载体。

---

## 验收标准（AC）

| 编号 | 验收项 | Pass 判据 |
|---|---|---|
| AC14a | 关卡有 BGM | 进关卡播放 forest.mp3 循环 |
| M18-1 | GameManager 常驻 | GameManager 注册为 Autoload，跨场景不销毁 |
| M18-2 | BGM 走 Music bus | BgmPlayer.bus = "Music"（bus.tres 的 New Bus 2 已重命名） |
| M18-3 | BGM 循环不中断 | 场景切换时 BGM 不重新从头播（Autoload 常驻） |

---

## 技术设计要点

### 新增场景与脚本（架构 §3.1 / §8）

```
scenes/game_manager.tscn   (Autoload 根)
└── GameManager (CanvasLayer, layer=50, process_mode=ALWAYS)
    ├── BgmPlayer (AudioStreamPlayer, bus=Music)
    └── 脚本: scripts/autoload/game_manager.gd (autoload, 禁 class_name)
```

### Autoload 注册

`project.godot [autoload]` 段注册 `GameManager=*res://scenes/game_manager.tscn`（启用）。

> 宪法 §3.2：Autoload 脚本**禁止** `class_name`，用全局名 `GameManager` 访问。

### game_manager.gd 职责（架构 §8.1）

```gdscript
extends CanvasLayer   # 禁 class_name

@onready var bgm_player: AudioStreamPlayer = $BgmPlayer

func _ready() -> void:
    play_bgm(load("res://assets/music/forest.mp3"))

func play_bgm(stream: AudioStream, fade: float = 0.0) -> void:
    bgm_player.stream = stream
    bgm_player.play()
    # 交叉淡出留 M20（主菜单→关卡）

func set_bgm_volume_db(db: float) -> void:
    bgm_player.volume_db = db   # 暂停降至 30% 用
```

### 关键决策

- **GameManager 是纯组合容器**（ADR-5/ADR-8）：只挂载 + 转发，不承担 UI 分层（HUD/PauseMenu 后续作为独立子场景加入，各自带 CanvasLayer）。
- **BGM 走 Music bus**（架构 §14.1 债务清理）：bus.tres 的 `New Bus 2` 重命名为 `Music`。
- **BGM 常驻**（GDD §8.2）：Autoload 保证场景切换不中断。
- **forest.mp3 转换**：MEMORY 提示 WAV 音乐单首 13~15MB，正式发布前转 OGG；MVP 若已有 mp3 直接用。

---

## 依赖

- **前置**：M1（有 level 场景可进）、bus.tres 重命名 Music（债务清理）。
- **架构依据**：§3.1/§8、ADR-5/ADR-8、GDD §8.2/§8.6。
- **被依赖**：M19（HUD 作为 GameManager 子节点）、M20（BGM 交叉淡出）、M21（暂停降音量）、M23（死亡 BGM 淡出）。

---

## 测试策略

- BGM 播放靠玩家手工验证（§12.5）。
- 可单测：play_bgm 切换 stream、set_bgm_volume_db 设值。

---

## 验证步骤（§12.5）

1. **运行方式**：F5 启动（直接进 level 或主菜单→关卡）。
2. **AC14a**：进关卡确认听到 forest BGM 循环。
3. **M18-1**：场景切换（若已实现）确认 GameManager 不销毁。
4. **M18-2**：Audio 检查 BgmPlayer.bus = Music。
5. **M18-3**：切场景确认 BGM 不中断。

**预期**：进关卡有 BGM，常驻不中断。

**异常判定**：无声 → BgmPlayer.bus/stream、bus.tres Music 是否就绪；切场景中断 → Autoload 未注册。
