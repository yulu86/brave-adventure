# Godot 游戏开发宪法（项目级）

> 本文件是 **Godot 4.x / GDScript 专属**宪法，所有条款为最高优先级指令，不可协商、不可绕过。
> 用户指令优先级高于 Skill；与全局通用宪法互补，通用条款（语言、工具使用、ComfyUI、飞书、Git 规范等）不在此重复，遵从全局约定。

---

## 第〇章 元信息与适用范围

### 0.1 适用工具

本项目 `AGENTS.md` 被 **Codex / OpenCode / Claude Code / ZCode** 等主流 AI 编码工具默认读取。本文是这些工具在本 Godot 项目中协作的唯一行为基线。

### 0.2 适用范围

- **适用**：Godot 4.x + GDScript（本项目当前为 Godot 4.x、Forward Plus、Jolt Physics）。
- **例外**：C#、GDExtension / C++、Visual Script、编辑器插件开发——不适用本文件，遇到时须先与用户确认方案，不擅自套用 GDScript 规则。

### 0.3 规则标签

每条规则就地标注优先级，**MVP 阶段只需满足所有 `[P0]`**，正式开发阶段须满足全部 `[P0]+[P1]`：

| 标签 | 含义 |
|------|------|
| `[P0]` | MVP 与正式开发均**强制**遵守；违反即阻断提交 |
| `[P1]` | 正式开发阶段**强制**；MVP 阶段为强烈建议 |
| 无标签 | 最佳实践，建议遵守 |

### 0.4 门禁标注

每条规则后可附验证方式，提交前可逐条核验：

| 标注 | 含义 |
|------|------|
| `【命令】` | 可执行的 CLI 命令（如 headless 测试） |
| `【MCP】` | 通过 Godot MCP 工具诊断（项目已配 `minimal-godot` / `godot-ultimate` / `godot-mcp` 三套） |
| `【Skill】` | 调用项目内 Godot Skill（architect / best-practices / patterns / code-review / static-analysis / ui） |

---

## 第一章 核心心智模型

1. **四要素**：`Node`（构建块）→ `Scene`（可复用节点树，存 `.tscn`）→ `Resource`（数据容器，存 `.tres`）→ `Signal`（事件通信）。
2. **`[P0]` 信号向上、调用向下（signal up, call down）**：子节点只发信号、不知父节点存在；父节点连接子信号并向下调用。禁止子节点反向调用父方法。
3. **`[P0]` 组合优于继承**：用"拥有"（has-a，组合/组件）表达能力，而非"继承"（is-a）。
4. **`[P0]` 数据驱动优于硬编码**：配置、数值、参数走 `@export` / `Resource`，不在代码里写死。
5. **三原则**：单一职责、松耦合（最小依赖、接口通信）、高内聚（相关功能集中）。

---

## 第二章 项目结构规范

### 2.1 `[P0]` 标准目录树

```
res://
├── scenes/            # .tscn 场景文件，按模块分子目录
├── scripts/           # .gd 脚本，与场景一一对应
├── assets/            # 静态资源
│   ├── sprites/       # 角色精灵
│   ├── sounds/        # 音效
│   ├── music/         # 背景音乐
│   ├── fonts/         # 字体
│   └── resources/     # .tres 资源（theme/tileset/texture/sound_bus）
├── addons/            # 第三方插件（GdUnit4 等）
├── test/              # 测试（三层）
│   ├── unit/          # 单元测试：单一类/函数
│   ├── integration/   # 集成测试：多模块协作，按 {模块} 子目录
│   └── functional/    # 功能/E2E 测试 + screenshots/
└── docs/              # 文档（.gdignore 屏蔽，不被 Godot 导入），按文档类型编号
    ├── README.md          # 项目入口：怎么跑、技术栈、快速索引
    ├── 01_需求/           # 需求与玩法设计（GDD）
    ├── 02_架构/           # 技术架构、ADR 决策记录
    ├── 03_美术规范/       # 美术风格、命名、尺寸、导入
    ├── 04_音频规范/       # 音效/音乐清单、Bus、音量
    ├── 05_测试策略/       # 测试分层、覆盖率目标、CI
    ├── 06_构建发布/       # 导出预设、多平台、版本
    └── 99_postmortem/    # 经验沉淀 MEMORY.md（通用/项目专属双区）
```

> `docs/` 完整目录规划与两阶段维护要求见 §13.1。

### 2.2 `[P0]` 命名

- 文件名、节点名：`snake_case`（`player_controller.gd`、`PlayerController` 节点用 PascalCase）。
- 场景与脚本**一一对应**：`player.tscn` ↔ `player.gd`，避免孤儿脚本。

### 2.3 `[P0]` 路径用途

- `res://`：只读游戏资源（随包发布）。
- `user://`：可读写用户数据（存档、设置、最高分），跨平台自动定位。

### 2.4 `[P0]` 版本控制

- `.godot/`、`.import/`、`export_presets.cfg`、构建产物须在 `.gitignore`。
- `.tres` / `.tscn` 文本格式提交，便于 diff 与 review。
- `docs/` 加 `.gdignore` 防止 Godot 扫描。

---

## 第三章 GDScript 编码规范

### 3.1 `[P0]` 命名约定

```gdscript
class_name PlayerController          # 类名：PascalCase
extends CharacterBody2D

signal health_changed(new_hp: int)  # 信号：past_tense_snake_case + 类型参数
const MAX_SPEED: float = 200.0      # 常量：SCREAMING_SNAKE_CASE
var current_health: int = 100       # 变量：snake_case
var _private_count: int = 0         # 私有：_ 前缀

func calculate_damage(base: int) -> int:  # 函数：snake_case + 返回类型
    pass
func _internal_helper() -> void:          # 私有函数：_ 前缀
    pass
```

### 3.2 `[P0]` 静态类型全标注

变量、函数签名、返回值、信号参数、`@onready` 引用**必须**显式类型标注。

```gdscript
var speed: float = 100.0
var items: Array[Item] = []
func get_damage() -> int:
@onready var sprite: Sprite2D = $Sprite2D
```

### 3.3 `[P0]` class_name 规则

- **Autoload / Singleton 脚本**：**禁止** `class_name`（用全局名访问，如 `GameManager`）。
- **非 Singleton 脚本**：**必须**定义 `class_name`，通过 `class_name` 做类型引用，**禁止**用 `preload`/`load` 后的变量名当类型别名。

### 3.4 `[P0]` 脚本结构顺序（自上而下）

```gdscript
@tool / class_name / extends
## 文档注释
# === Signals ===
# === Enums ===
# === Exports ===（用 @export_group 分组）
# === Constants ===
# === Public Variables ===
# === Private Variables ===（_ 前缀）
# === Onready ===（@onready + 类型）
# === Lifecycle ===（_ready / _process / _physics_process）
# === Public Methods ===
# === Private Methods ===
```

### 3.5 `[P0]` 文档与卫生

- **代码除注释外无中文**（标识符、字符串字面量用英文/拼音，注释可中文）。
- 每个 `func`、`enum` 及枚举值、`signal` 须有 `##` 注释说明用途。
- 参数名**不与节点内置属性冲突**（`name`、`position`、`scale` 等）。
- 枚举/变量命名精确反映用途，删除不可达代码（如 `match` 全覆盖后多余 `return`）。

**门禁**：`【MCP】` `minimal-godot_get_diagnostics`（0 语法/类型错误）、`【MCP】` `godot-ultimate_godot_lint_file`（0 error 0 warning）、`【Skill】` `godot-best-practices`。

---

## 第四章 场景与节点规范

### 4.1 `[P0]` 节点引用

```gdscript
# ✅ 推荐：@onready + 类型标注
@onready var health_bar: ProgressBar = $UI/HealthBar
# ✅ 推荐：关键节点用 % 唯一名
@onready var player: Player = %Player
# ❌ 禁止：get_node() in _ready()、深路径 $A/B/C/D、get_parent().get_parent() 链
```

### 4.2 `[P0]` 场景设计

- 每个场景**自包含、可复用、可实例化**：不依赖特定父节点路径。
- 关键跨场景节点用 `%UniqueName`（Scene → Access as Unique Name）。
- `queue_free()` 前用 `is_instance_valid(node)` 检查引用，**禁止** `!= null` 判定已释放节点。

**门禁**：`【MCP】` `godot-ultimate_godot_validate_scenes`（场景断裂引用 = 0）。

---

## 第五章 信号与通信

### 5.1 `[P0]` 信号驱动架构

```gdscript
# 子节点：发信号，不知父节点
class_name HealthComponent extends Node
signal died
func take_damage(amount: int) -> void:
    if _hp <= 0: died.emit()      # ✅ .emit()，非 emit_signal("died")

# 父节点：连接子信号并向下调用
func _ready() -> void:
    health.died.connect(_on_died)  # ✅ connect，非 .connect("died", ...)
```

### 5.2 `[P0]` 类型化信号

```gdscript
signal score_updated(new: int, old: int)      # ✅ 带类型参数
signal target_acquired(target: Node2D, d: float)
# ❌ 禁止 emit_signal("x") / connect("x", ...) 字符串形式
```

### 5.3 `[P1]` 通信解耦（正式开发）

- **EventBus**：Autoload 全局信号总线，**仅放精简的跨系统事件**，不塞业务逻辑。
- **组件系统**：`HealthComponent` / `HitboxComponent` / `HurtboxComponent` 等可复用组件，has-a 组合优于继承。
- `[P0]` 禁止子节点直接调用父节点方法。

---

## 第六章 资源与数据驱动

### 6.1 `[P1]` Resource 承载数据

```gdscript
class_name WeaponData extends Resource
@export var damage: int = 10
@export var icon: Texture2D
```

- 配置数据存 `.tres`（可在 Inspector 可视化编辑、可复用、可继承）。
- **运行时须 `duplicate()` 副本**，避免修改原件污染共享数据。

### 6.2 `[P1]` 加载策略

| 场景 | 方法 |
|------|------|
| 小/关键资源（编译期） | `preload("res://...")` |
| 大/可选资源（运行期） | `load("res://...")` 并缓存引用 |
| 异步防卡顿 | `ResourceLoader.load_threaded_request` + 轮询 status |

---

## 第七章 架构模式

### 7.1 `[P0]` 状态机

- **简单状态**：`enum State { IDLE, WALK }` + `match current_state`。
- **复杂状态**：`StateMachine`（Node）+ `State`（Node 子类）节点模式，每状态 `enter/exit/update/physics_update/handle_input`。详见 `【Skill】` `godot-gdscript-patterns`。

### 7.2 `[P1]` 对象池 / 组件 / Autoload（正式开发）

- **对象池**：高频创建销毁的对象（子弹、特效）用 `ObjectPool` 复用，禁 `_process` 内 `load`/`instantiate`。
- **Autoload**：仅用于真全局服务（GameManager / SaveManager / AudioManager / EventBus），**禁止**塞游戏逻辑（难测试、紧耦合）。
- **组件系统**：能力以组件形式挂载（`HealthComponent`），`has_method()` / `is` 判定能力而非类型硬依赖。

---

## 第八章 UI 规范

> 详细 UI 模式见 `【Skill】` `godot-ui`。

### 8.1 `[P1]` 布局与分层

- 用 `Control` + 容器节点（VBox/HBox/Grid/Margin/Scroll）做自适应布局，避免手算坐标。
- `CanvasLayer` 分层管理渲染顺序（HUD=10、Pause=100），避免 z_index 混乱。
- `Theme` 存为 `.tres` 资源（`assets/resources/theme/`），复用与继承。

### 8.2 `[P1]` 可访问性

- 所有交互控件**必须**支持键盘/手柄：配 `focus_neighbor_*` focus 链、入口 `grab_focus()`。
- 隐藏 UI 时 `process_mode = PROCESS_MODE_DISABLED` 省性能。

---

## 第九章 测试规范

### 9.1 `[P0]` 框架与分层

- 默认测试框架：**GdUnit4**（见 [godot-gdunit-labs/gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4)，原生支持 GDScript、CI 集成好）。
- 三层测试目录：`test/unit/`（单类/函数）、`test/integration/{模块}/`（多模块协作）、`test/functional/`（端到端 + 截图）。

### 9.2 `[P0]` TDD 小循环（Red-Green-Refactor，单测驱动）

> **强制小步快跑**：每次只生成 **1 个测试方法** → 编码使其通过 → 重构，循环推进。禁止"先写一批测试再实现"。

```
[Skill] test-driven-development 流程：
1. Red：写 1 个失败测试方法（描述单一行为/边界）
2. Green：写**刚好**满足该用例的最小实现代码（不过度设计）
3. Refactor：在测试保护下重构，保持绿
4. 回到 1，写下一个测试方法
```

- 每个公开方法/分支/边界至少 1 个测试。
- 测试命名描述行为：`func test_take_damage_reduces_health()`。
- 用 `add_child_autoqfree(child)` 代替 `add_child` + `queue_free`（自动清理）。
- 浮点比较用 `assert_almost_eq`，**禁止** `assert_eq` 比浮点。

### 9.3 `[P0]` Headless CI 流水线

两步流水线（参考 [CI-tested GUT for Godot 4](https://medium.com/@kpicza/ci-tested-gut-for-godot-4-fast-green-and-reliable-c56f16cde73d)、[Saltares: Godot CI](https://saltares.com/run-automated-tests-for-your-godot-game-on-ci)）：

```bash
# Step 1: headless 预热导入资源（避免首次导入导致测试 flaky）
godot --headless --import

# Step 2: headless 运行 GdUnit4 测试套件
godot --headless --path . -s addons/gdUnit4/src/runner/GdUnitRunnerCmd.gd -a tests/
```

### 9.4 覆盖率

- `[P1]`（正式开发）≥ 80%；`[P0]`（MVP）覆盖关键逻辑路径。
- 门禁：`【MCP】` `godot-ultimate_godot_get_test_coverage`。

---

## 第十章 质量门禁（提交前必过）

> 指标体系复用 `【Skill】` `godot-static-analysis` 的 C01–C12，提交前**必须**全部达标。

### 10.1 `[P0]` 提交前检查清单

| 编号 | 门禁项 | 阈值 | 命令 / MCP |
|------|--------|------|-----------|
| G01 | 语法/类型错误 | 0 | `【MCP】` `minimal-godot_scan_workspace_diagnostics` |
| G02 | Lint（error + warning） | 各 0 | `【MCP】` `godot-ultimate_godot_lint_project` |
| G03 | 场景断裂引用 | 0 | `【MCP】` `godot-ultimate_godot_validate_scenes` |
| G04 | 项目全局验证 | 全通过 | `【MCP】` `godot-ultimate_godot_validate_project` |
| G05 | 未定义 Input Action | 0 | `【MCP】` `godot-ultimate_godot_validate_inputs` |
| G06 | headless 测试套件 | 全绿 | `【命令】` `godot --headless` 见 §9.3 |

### 10.2 `[P1]` 正式开发附加门禁

| 编号 | 门禁项 | 阈值 | MCP |
|------|--------|------|-----|
| G07 | 函数圈复杂度 | ≤ 10 | `godot-ultimate_godot_get_complexity` |
| G08 | 代码重复（≥5 行） | 0 组 | `godot-ultimate_godot_find_duplication` |
| G09 | 死代码（未用 func/var/signal） | 0 | `godot-ultimate_godot_detect_dead_code` |
| G10 | 未用文件 | 0 | `godot-ultimate_godot_find_unused_files` |
| G11 | 测试覆盖率 | ≥ 80% | `godot-ultimate_godot_get_test_coverage` |
| G12 | 项目健康度综合评分 | ≥ 80 | `godot-ultimate_godot_project_health` |
| G13 | 代码模式合规 | 0 违规 | `godot-ultimate_godot_check_patterns` |

---

## 第十一章 性能规范

> `[P1]` 正式开发强制，MVP 阶段量力而行。

1. `_process` / `_physics_process` 内**禁止** `load`、频繁内存分配、轮询未变状态。
2. 缓存 `@onready` 引用与计算结果，避免每帧重复求值。
3. 高频对象用对象池；离屏节点 `process_mode = DISABLED` 或 `visible = false`。
4. 大资源用 `ResourceLoader.load_threaded_*` 异步加载，防主线程卡顿。
5. 静态类型全标注不仅是规范，也利于 GDScript 性能。

---

## 第十二章 AI Agent 协作守则

### 12.1 `[P0]` 场景文件必须由工具生成，禁止手写

`.tscn` / `.tres` 文件**禁止**纯手工编写文本，必须通过以下方式之一：
- Godot 编辑器可视化编辑；
- `【MCP】` `godot-mcp`（`create_scene` / `add_node` / `save_scene` / `load_sprite`）；
- `【MCP】` `godot-ultimate`（`godot_generate_feature` / `godot_generate_from_template`）。

> 理由：手写 `.tscn` 极易产生 UID、sub_resource 引用错误，难以调试。

### 12.2 `[P0]` Skill 链不可绕过

当 CLI 或 Skill 已提供能力，**禁止**绕过它们直接调底层 API 或手写封装。Godot 开发遵循 skill 协作链：

```
架构设计  →【Skill】godot-architect（只设计，不写码）
编码实现  →【Skill】godot-best-practices / godot-gdscript-patterns
TDD 循环 →【Skill】test-driven-development（§9.2 单测小循环）
代码检视 →【Skill】godot-code-review（逐文件，用户确认）
质量验证 →【Skill】godot-static-analysis（§10 门禁）
UI 开发  →【Skill】godot-ui
```

### 12.3 `[P0]` 增量与小步验证

- 每个改动**小步可验证**：一次只动一个职责，立即跑测试/诊断。
- 架构级变更**必须**先经 `【Skill】` `godot-architect` 出设计，再实现。
- 实现完成后**必须**经 `【Skill】` `godot-code-review` 与用户逐文件确认。

### 12.4 `[P0]` 经验沉淀与收尾闭环

每次任务/检视后，将经验追加到 `docs/99_postmortem/MEMORY.md`，并按**双区**区分：
- **通用经验**：跨 Godot 项目可复用的规则（如"浮点用 assert_almost_eq"）。
- **项目专属经验**：仅适用本项目的约定（如特定模块的实现细节）。

**沉淀后收尾闭环**（强制，不可跳过）：
1. **提交经验文档**：经验沉淀完成后，**独立 commit** MEMORY.md（与代码 commit 分开），消息格式 `docs: 沉淀本次{任务}经验`（遵从全局 §4.2）。
2. **飞书通知**：使用 `【Skill】` `lark-im` 向用户发送任务完成通知。通知所需信息**全部从项目根 `.env` 读取**（遵从全局 §1.4 / §2.4），**禁止**在代码或配置中硬编码凭证：

   | 环境变量 | 用途 |
   |---------|------|
   | `FEISHU_APP_ID` | 飞书应用 ID，用于获取 tenant_access_token 鉴权 |
   | `FEISHU_APP_SECRET` | 飞书应用 Secret，配合 APP_ID 鉴权 |
   | `FEISHU_USER_ID` | 接收通知的用户 open_id（确定消息发给谁） |

   通知内容至少含：任务摘要、变更文件数、是否全部门禁通过、经验沉淀要点。

> 顺序约束：代码提交 → 经验沉淀 → 经验文档提交 → 飞书通知（见 §14 工作流）。禁止在经验文档提交前发送完成通知。

---

## 第十三章 文档交付索引与一致性校验

### 13.1 `[P0]` docs/ 目录文档规划（按文档类型编号）

`docs/` 顶层按**文档类型/生命周期**编号分目录（与 `99_postmortem/` 风格一致）。每个目录存一类文档，文件命名 `{两位序号}_{中文名称}.md`（遵从全局 §3.1）。

#### 目录结构与职责

| 目录 | 职责 | 典型文件 |
|------|------|---------|
| `README.md` | 项目入口：环境/怎么跑/技术栈/文档索引 | `README.md` |
| `01_需求/` | 需求与玩法设计（Game Design Document） | `01_核心玩法.md`、`02_操作设计.md`、`03_关卡设计.md` |
| `02_架构/` | 技术架构、场景树、状态机、接口定义、ADR | `01_技术架构.md`、`02_{模块}架构.md`、`03_ADR决策记录/{NN}_{决策}.md` |
| `03_美术规范/` | 美术风格、精灵命名/尺寸、导入设置、调色板 | `01_美术总览.md`、`02_精灵规范.md`、`03_调色板.md` |
| `04_音频规范/` | 音效/音乐清单、Audio Bus 路由、音量基线 | `01_音频总览.md`、`02_音频清单.md`、`03_Bus路由.md` |
| `05_测试策略/` | 测试分层、覆盖率目标、CI 流水线、测试约定 | `01_测试总览.md`、`02_覆盖率目标.md`、`03_CI流水线.md` |
| `06_构建发布/` | 导出预设、多平台、版本号、发布检查清单 | `01_导出预设.md`、`02_多平台发布.md`、`03_发布检查.md` |
| `07_story/` | 用户故事（Story）文档，按模块分子目录（可选，按需使用） | `01_{模块}/01_{故事名}.md` |
| `99_postmortem/` | 经验沉淀（通用/项目专属双区） | `MEMORY.md`（见 §12.4） |

> 设计文档须用 **Mermaid** 绘制架构图/状态机图/流程图（遵从全局 §3.3）。
> 架构类文档须含：场景树结构、核心接口/信号定义、状态机图、依赖关系。

#### 两阶段文档维护要求

| 文档 | MVP 阶段 `[P0]` | 正式开发阶段 `[P1]` |
|------|:---:|:---:|
| `README.md`（项目入口） | ✅ 必备 | ✅ 持续维护 |
| `01_需求/01_核心玩法.md`（核心玩法 GDD） | ✅ 必备 | ✅ 持续维护（扩展关卡/操作设计） |
| `02_架构/01_技术架构.md`（技术架构） | ✅ 必备 | ✅ 持续维护 |
| `02_架构/{NN}_{模块}架构.md`（各模块架构） | 🟡 按需（核心模块） | ✅ 每模块必备 |
| `02_架构/03_ADR决策记录/`（架构决策） | 🟡 关键决策记录 | ✅ 重要决策必记 |
| `03_美术规范/` | 🟡 大纲即可 | ✅ 完整规范 |
| `04_音频规范/` | 🟡 大纲即可 | ✅ 完整规范 |
| `05_测试策略/` | 🟡 测试约定（本宪法 §9） | ✅ 完整策略 + 覆盖率目标 |
| `06_构建发布/` | 🟡 MVP 导出预设 | ✅ 多平台完整 |
| `07_story/`（Story 文档） | ⬜ 按需 | ⬜ 按需 |
| `99_postmortem/MEMORY.md` | ✅ 必备 | ✅ 持续沉淀 |

> 图例：✅ 强制维护 ｜ 🟡 按需/大纲即可 ｜ ⬜ 该阶段不强制

**MVP 阶段最小必备集合（4 件）**：`README.md` + `01_需求/01_核心玩法.md` + `02_架构/01_技术架构.md` + `99_postmortem/MEMORY.md`。其余 🟡 项随功能落地按需补全，但须在对应功能实现前先出大纲，避免"先写码后补文档"。

### 13.2 `[P0]` 文档交付索引（开发过程中按阶段读取/产出）

开发过程中**必须**按阶段读取/产出对应文档，禁止跳过：

| 阶段 | 应读文档 | 应产文档 | 位置约定 |
|------|---------|---------|---------|
| 需求/架构 | `01_需求/`、历史 `02_架构/`、`MEMORY.md` | 架构设计文档（含 Mermaid） | `02_架构/{NN}_{模块}架构.md` |
| Story 拆分（可选） | `01_需求/`、`02_架构/{模块}` | Story 文档 | `07_story/{NN}_{模块}/{NN}_{故事}.md` |
| 编码实现 | 对应 `02_架构/` 设计文档、`MEMORY.md` | 代码 + 注释 | `scripts/` `scenes/` |
| 测试 | `05_测试策略/`、本宪法 §9 | 测试用例 | `test/{unit,integration,functional}/` |
| 检视/复盘 | 本宪法 §3-§8、`MEMORY.md` | 检视总结 | `99_postmortem/MEMORY.md` |
| 构建发布 | `06_构建发布/` | 发布产物 + 版本 | `build/` |

### 13.3 `[P0]` 设计-实现一致性校验

每个功能交付前**必须**对比"设计文档"与"实际代码"，确认一致性：

1. **读取该模块的设计文档**（架构图、接口定义、状态机图）。
2. **对照实际 `.gd` / `.tscn`**：节点结构、信号、接口、状态枚举是否与设计吻合。
3. **不一致即修正**：代码偏离设计时改代码；设计已过时时更新文档并说明原因。
4. 在代码检视（§12.2）中**显式声明一致性结论**，写入检视总结。


---

## 第十四章 工作流总览

```
需求 →【Skill: architect】 架构设计文档(含 Mermaid 图)
     →【Skill: best-practices + TDD 小循环】 1个测试 → 最小实现 → 重构（循环）
     →【MCP: minimal-godot/godot-ultimate】 诊断 + lint（§3 门禁）
     →【Skill: code-review】 逐文件检视 + 用户确认 + 设计-实现一致性(§13.2)
     →【命令: headless】 测试套件全绿（§9.3）
     →【Skill: static-analysis】 §10 全部门禁达标
     → 提交代码（全局 §4.2 commit 规范）
     → 经验沉淀 docs/99_postmortem/MEMORY.md（§12.4）
     → 提交经验文档（独立 commit，如 `docs: 沉淀本次经验`）
     →【Skill: lark-im】 飞书通知用户任务完成
```

---

## 第十五章 阶段化速查表

### 15.1 MVP 阶段（满足所有 `[P0]`）

- ✅ 编码规范（命名、静态类型、class_name、无中文、文档注释）—— §3
- ✅ 场景/节点（@onready+类型、%UniqueName、自包含场景）—— §4
- ✅ 信号驱动（signal up call down、.emit()）—— §5
- ✅ 状态机（复杂状态用 StateMachine+State）—— §7.1
- ✅ TDD 小循环（1 测试 → 实现 → 重构）—— §9.2
- ✅ Headless 测试流水线 —— §9.3
- ✅ 提交前门禁 G01–G06 —— §10.1
- ✅ 场景文件工具生成、skill 链、增量验证 —— §12
- ✅ 文档最小必备集合（README + 核心玩法 + 技术架构 + MEMORY）—— §13.1

### 15.2 正式开发阶段（全 `[P0]` + `[P1]`）

- ➕ 资源数据驱动（Resource duplicate、加载策略）—— §6
- ➕ 对象池 / 组件系统 / 精简 Autoload —— §7.2
- ➕ UI（Control+容器、CanvasLayer、Theme、可访问性）—— §8
- ➕ 性能规范（_process 禁忌、异步加载）—— §11
- ➕ 测试覆盖率 ≥ 80% —— §9.4
- ➕ 完整门禁 G07–G13 —— §10.2
- ➕ 文档全量维护（各模块架构 + ADR + 美术/音频/测试/构建规范）—— §13.1

---

## 附录

### A. 命令速查

> **`godot` 命令路径从系统环境变量 `$GODOT_HOME` 读取**。
> `$GODOT_HOME` 指向 Godot 可执行文件所在**目录**（如 `.app/Contents/MacOS`），可执行文件名为 `godot`。
> 使用前所有命令用 `$GODOT_HOME/godot`（或先 `alias godot="$GODOT_HOME/godot"`），**禁止**硬编码绝对路径，**禁止**从 `.env` 读取。

```bash
# 校验 $GODOT_HOME 已在系统环境变量中设置（缺失则报错退出）
[ -z "$GODOT_HOME" ] && { echo "错误：系统环境变量 GODOT_HOME 未设置" >&2; exit 1; }
alias godot="$GODOT_HOME/godot"

# Headless 预热 + 测试（§9.3）
godot --headless --import
godot --headless --path . -s addons/gdUnit4/src/runner/GdUnitRunnerCmd.gd -a tests/

# 语法检查（备选）
godot --headless --check-only --script scripts/xxx.gd
```

### B. MCP 工具索引（项目已配）

- `minimal-godot`：`get_diagnostics` / `scan_workspace_diagnostics`（LSP 诊断，G01）
- `godot-ultimate`：lint / validate_scenes / validate_project / get_test_coverage / project_health 等（G02–G13）
- `godot-mcp`：`create_scene` / `add_node` / `save_scene` / `load_sprite`（场景生成，§12.1）

### C. Skill 索引（项目内）

`godot-architect` · `godot-best-practices` · `godot-gdscript-patterns` · `godot-code-review` · `godot-static-analysis` · `godot-ui`

### D. 业界参考

- [AGENTS.md 官方规范](https://agents.md/) —— AI Agent 项目指令文件标准
- [GodotPrompter](https://github.com/jame581/GodotPrompter) —— Godot 4.x AI Agent 技能框架（GDScript）
- [gd-agentic-skills](https://knightli.com/en/2026/06/13/gd-agentic-skills-godot-ai-skills/) —— Godot 开发经验转 AI 可调用技能
- [GdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) —— Godot 4 单元测试框架
- [CI-tested GUT for Godot 4](https://medium.com/@kpicza/ci-tested-gut-for-godot-4-fast-green-and-reliable-c56f16cde73d) —— Headless CI 两步流水线
- [Saltares: Run Godot tests on CI](https://saltares.com/run-automated-tests-for-your-godot-game-on-ci) —— Godot CI 实践
- [Godot Singletons/Autoload 官方文档](https://docs.godotengine.org/en/latest/tutorials/scripting/singletons_autoload.html)
