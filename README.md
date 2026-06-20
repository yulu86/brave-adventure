# 勇士的冒险（Brave Adventure）

> 2D 横版像素动作闯关游戏。当前阶段：**MVP**（单关卡可玩闭环）。

![游戏设计图-关卡开始](docs/00_scratch/game_play.png)
![游戏设计图-关卡出口](docs/00_scratch/game_play_2.png)

---

## 1. 技术栈

| 项 | 值 |
|---|---|
| 引擎 | Godot 4.6（`config/features=4.6`） |
| 渲染 | Forward Plus（Windows 驱动 D3D12） |
| 物理引擎 | Jolt Physics（`3d/physics_engine=Jolt Physics`） |
| 脚本语言 | GDScript 2.x（静态类型全标注） |
| 测试框架 | GdUnit4（`addons/gdUnit4/`，已启用） |
| 美术资产 | `Legacy-Fantasy High Forest 2.3`（itch.io 免费，16-bit 像素） |
| 字体 | SmileySans-Oblique（中文 UI） |

### 1.1 关键渲染约束

- 视口 `480×270`，窗口 `1920×1080`，`window/stretch/mode="viewport"`（整数缩放，保持像素硬边）。
- 全局 `textures/canvas_textures/default_texture_filter=0`（Nearest），所有像素资产须符合此基准。
- 瓦片网格 16×16，主角帧 64×80，小怪帧 32×32。

---

## 2. 环境要求

| 依赖 | 版本 / 说明 |
|---|---|
| Godot Engine | **4.6.x**（与 `project.godot` 一致） |
| 系统环境变量 | `GODOT_HOME` 指向 Godot 可执行文件**所在目录** |
| Git LFS | 本仓库美术/音频资产为大二进制文件，克隆前建议确认是否启用 LFS（见 `.gitattributes`） |

> ⚠️ 本机 `GODOT_HOME` 当前指向 exe 文件本身而非目录，命令行调用时请按实际路径调整（见 §3 命令示例）。

---

## 3. 怎么跑

### 3.1 编辑器内运行（推荐开发）

1. 用 Godot 4.6 打开本仓库根目录的 `project.godot`。
2. 首次打开会自动导入资源（`assets/`），等待右下角导入完成。
3. 按 `F5` 运行主场景（MVP 主场景待定，见架构文档）。

### 3.2 命令行（headless / CI）

> 宪法要求命令路径从 `$GODOT_HOME/godot` 读取，禁止硬编码绝对路径。

```bash
# 1. 预热导入（首次或资产变更后必做）
"$GODOT_HOME/godot" --headless --import

# 2. 跑测试套件（GdUnit4）
"$GODOT_HOME/godot" --headless --path . \
  -s addons/gdUnit4/src/runner/GdUnitRunnerCmd.gd -a tests/

# 3. 单脚本语法检查（备选）
"$GODOT_HOME/godot" --headless --check-only --script scripts/xxx.gd
```

### 3.3 质量门禁（提交前）

依赖 MCP 工具（`minimal-godot` / `godot-ultimate`）与项目内 Skill，详见 `AGENTS.md` 第十章。最低基线：0 语法/类型错误、0 lint error/warning、0 场景断裂引用、headless 测试全绿。

---

## 4. 项目结构

```
brave-adventure/
├── project.godot           # 引擎配置
├── AGENTS.md               # Godot 开发宪法（项目级，最高优先级指令）
├── addons/                 # 第三方插件（GdUnit4）
├── assets/                 # 美术/音频/字体/资源(.tres)
│   ├── sprites/            #   精灵表（Legacy-Fantasy 包等）
│   ├── music/              #   BGM（.mp3，待转 .ogg）
│   ├── sounds/             #   音效（.ogg/.wav）
│   ├── fonts/              #   字体
│   ├── resources/          #   .tres 数据资源（tileset/ 等）
│   ├── themes/             #   UI 主题
│   └── bus/                #   AudioBus 配置
├── scenes/                 # 场景文件 .tscn（MVP 待建）
├── scripts/                # 脚本 .gd（MVP 待建）
├── test/                   # 测试（GdUnit4）
│   ├── unit/               #   单元测试
│   ├── integration/        #   集成测试
│   └── functional/         #   端到端 + 截图
└── docs/                   # 文档（已加 .gdignore，不参与导入）
    ├── 00_scratch/         #   早期草稿/参考截图
    ├── 01_需求/            #   需求与玩法设计（GDD）
    ├── 02_架构/            #   技术架构（MVP 待建）
    ├── 03_美术规范/        #   美术资产清单/规范
    ├── 04_音频规范/        #   音频资产清单/规范
    └── 99_postmortem/      #   经验沉淀（MEMORY.md）
```

---

## 5. 文档索引

| 文档 | 说明 |
|---|---|
| [`AGENTS.md`](AGENTS.md) | **Godot 开发宪法**（最高优先级行为基线，开发前必读） |
| [核心玩法设计（GDD）](docs/01_需求/01_核心玩法.md) | MVP 玩法/关卡/数值/状态机/场景流设计 |
| [美术资产清单](docs/03_美术规范/01_美术资产清单.md) | 精灵资产/命名/尺寸/动画帧数映射 |
| [音频资产清单](docs/04_音频规范/01_音频资产清单.md) | BGM/音效清单与 Bus 路由 |
| [经验沉淀 MEMORY](docs/99_postmortem/MEMORY.md) | 历史任务教训（每个任务开始前必读） |

> 架构文档（`docs/02_架构/`）待补：MVP 全量技术架构设计中。

---

## 6. 开发协作

本项目使用 AI 辅助开发，协作流程与质量门禁统一定义在 [`AGENTS.md`](AGENTS.md)（Godot 4.x + GDScript 项目级宪法）。核心要点：

- **工作流**：架构设计 → TDD 小循环（Red-Green-Refactor）→ MCP 诊断/lint → 代码检视 → headless 测试 → 编辑器重载 → 玩家手工验证 → 提交 → 经验沉淀。
- **两强制关卡**：可视化搭建协作（AI 写初值 + 用户精调视觉属性）、玩家手工验证（黑盒验收）。
- **Git 提交规范**：`{type}: {description}`，type ∈ `feat/fix/perf/refactor/test/docs/config/delete`。
